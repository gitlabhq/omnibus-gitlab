PROJECT=gitlab
RELEASE_BUCKET=downloads-packages
RELEASE_BUCKET_REGION=eu-west-1
SECRET_DIR:=$(shell openssl rand -hex 20)
PLATFORM_DIR:=$(shell bundle exec support/ohai-helper platform-dir)
PACKAGECLOUD_USER=gitlab
PACKAGECLOUD_OS:=$(shell bundle exec support/ohai-helper repo-string)
ifeq ($(shell support/is_gitlab_ee.sh; echo $$?), 0)
RELEASE_PACKAGE=gitlab-ee
TAG_MATCH='*[+.]ee.*'
else
RELEASE_PACKAGE=gitlab-ce
TAG_MATCH='*[+.]ce.*'
endif
RELEASE_VERSION?=$(shell bundle exec support/release_version.rb)
LATEST_TAG:=$(shell git -c versionsort.prereleaseSuffix=rc tag -l ${TAG_MATCH} --sort=-v:refname | head -1)
LATEST_STABLE_TAG:=$(shell git -c versionsort.prereleaseSuffix=rc tag -l ${TAG_MATCH} --sort=-v:refname | awk '!/rc/' | head -1)
ifdef NIGHTLY
DOCKER_TAG:=nightly
else
DOCKER_TAG:=$(RELEASE_VERSION)
endif

populate_cache:
	bin/omnibus cache populate

restore_cache_bundle:
	if test -f cache/${PLATFORM_DIR}; then git clone --mirror cache/${PLATFORM_DIR} /var/cache/omnibus/cache/git_cache/opt/gitlab; fi;

pack_cache_bundle:
	git --git-dir=/var/cache/omnibus/cache/git_cache/opt/gitlab bundle create cache/${PLATFORM_DIR} --tags

build:
	bin/omnibus build ${PROJECT} --log-level info

# license_check should be run after `build`, but because build calls omnibus which
# does a rebuild every call, we're not setting that specific dependency for when
# working on changes to support/license_check.sh. See the order of `test`.
license_check:
	bash support/license_check.sh
# If this task were called 'release', running 'make release' would confuse Make
# because there exists a file called 'release.sh' in this directory. Make has
# built-in rules on how to build .sh files. By calling this task do_release, it
# can coexist with the release.sh file.
do_release: no_changes on_tag purge build license_check move_to_platform_dir sync packagecloud

# Redefine RELEASE_BUCKET for test builds
test: RELEASE_BUCKET=omnibus-builds
test: no_changes purge build license_check move_to_platform_dir sync
ifdef NIGHTLY
test: packagecloud
endif

# Redefine PLATFORM_DIR for Raspberry Pi 2 packages.
do_rpi2_release: PLATFORM_DIR=raspberry-pi2
do_rpi2_release: no_changes purge build license_check move_to_platform_dir sync packagecloud

no_changes:
	git diff --quiet HEAD

on_tag:
	git describe --exact-match

purge:
	# Force a new clone of gitlab-rails because we change remotes for CE/EE
	rm -rf /var/cache/omnibus/src/gitlab-rails
	# Avoid mysterious GitFetcher omnibus errors
	rm -rf /var/cache/omnibus/src/gitlab-shell /var/cache/omnibus/src/gitlab-workhorse
	# Force a new download of Curl's certificate bundle because it gets updated
	# upstream silently once every while
	rm -rf /var/cache/omnibus/cache/cacert.pem
	# Clear out old packages to prevent uploading them a second time to S3
	rm -rf /var/cache/omnibus/pkg
	mkdir -p pkg
	(cd pkg && find . -delete)

# Instead of pkg/gitlab-xxx.deb, put all files in pkg/ubuntu/gitlab-xxx.deb
move_to_platform_dir:
	mv pkg ${PLATFORM_DIR}
	mkdir pkg
	mv ${PLATFORM_DIR} pkg/

sync: move_to_secret_dir s3_sync

move_to_secret_dir:
	if support/is_gitlab_ee.sh ; then \
	  mv pkg ${SECRET_DIR} \
	  && mkdir pkg \
	  && mv ${SECRET_DIR} pkg/ \
	  ; fi

docker_cleanup:
	-docker ps -q -a | xargs docker rm -v
	-docker images -f dangling=true -q | xargs docker rmi
	-docker images | grep $(RELEASE_PACKAGE) | awk '{print $$3}' | xargs docker rmi -f

docker_build: docker_cleanup
	echo PACKAGECLOUD_REPO=$(PACKAGECLOUD_REPO) > docker/RELEASE
	echo RELEASE_PACKAGE=$(RELEASE_PACKAGE) >> docker/RELEASE
	echo RELEASE_VERSION=$(RELEASE_VERSION) >> docker/RELEASE
	docker build --pull -t $(RELEASE_PACKAGE):latest -f docker/Dockerfile docker/

docker_push:
	docker tag -f $(RELEASE_PACKAGE):latest gitlab/$(RELEASE_PACKAGE):$(DOCKER_TAG)
	docker push gitlab/$(RELEASE_PACKAGE):$(DOCKER_TAG)

docker_push_rc:
	# push as :rc tag, the :rc is always the latest tagged release
	docker tag -f $(RELEASE_PACKAGE):latest gitlab/$(RELEASE_PACKAGE):rc
	docker push gitlab/$(RELEASE_PACKAGE):rc

docker_push_latest:
	# push as :latest tag, the :latest is always the latest stable release
	docker tag -f $(RELEASE_PACKAGE):latest gitlab/$(RELEASE_PACKAGE):latest
	docker push gitlab/$(RELEASE_PACKAGE):latest

do_docker_master:
ifdef NIGHTLY
do_docker_master: docker_build docker_push
endif

do_docker_release: no_changes on_tag docker_build docker_push
# The rc should always be the latest tag, stable or upcoming release
ifeq ($(shell git describe --exact-match --match ${LATEST_TAG} > /dev/null 2>&1; echo $$?), 0)
do_docker_release: docker_push_rc
endif
# The lastest tag is alwasy the latest stable
ifeq ($(shell git describe --exact-match --match ${LATEST_STABLE_TAG} > /dev/null 2>&1; echo $$?), 0)
do_docker_release: docker_push_latest
endif

s3_sync:
	aws s3 sync pkg/ s3://${RELEASE_BUCKET} --acl public-read --region ${RELEASE_BUCKET_REGION}
	# empty line for aws status crud
	# Replace FQDN in URL and deal with URL encoding
	echo "Download URLS:" && find pkg -type f | sed -e "s|pkg|https://${RELEASE_BUCKET}.s3.amazonaws.com|" -e "s|+|%2B|"

packagecloud:
	bash support/packagecloud_upload.sh ${PACKAGECLOUD_USER} ${PACKAGECLOUD_REPO} ${PACKAGECLOUD_OS}
