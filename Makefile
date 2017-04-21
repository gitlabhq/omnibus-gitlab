PROJECT=gitlab
RELEASE_BUCKET=downloads-packages
RELEASE_BUCKET_REGION=eu-west-1
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
	bundle exec rake build:project

# license_check should be run after `build` only. This is because otherwise
# entire package will be built everytime lib/gitlab/tasks/license_check.rake
# is invoked. This will be troublesome while modifying the license_check task.
license_check:
	bundle exec rake license:check
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
	bundle exec rake build:purge_cache

# Instead of pkg/gitlab-xxx.deb, put all files in pkg/ubuntu/gitlab-xxx.deb
move_to_platform_dir:
	mv pkg ${PLATFORM_DIR}
	mkdir pkg
	mv ${PLATFORM_DIR} pkg/

docker_cleanup:
	-bundle exec rake docker:clean[$(RELEASE_VERSION)]

docker_build: docker_cleanup
	echo PACKAGECLOUD_REPO=$(PACKAGECLOUD_REPO) > docker/RELEASE
	echo RELEASE_PACKAGE=$(RELEASE_PACKAGE) >> docker/RELEASE
	echo RELEASE_VERSION=$(RELEASE_VERSION) >> docker/RELEASE
	echo DOWNLOAD_URL=$(shell find pkg/ubuntu-16.04 -type f -name '*.deb'| sed -e "s|pkg|https://${RELEASE_BUCKET}.s3.amazonaws.com|" -e "s|+|%2B|") >> docker/RELEASE
	bundle exec rake docker:build[$(RELEASE_PACKAGE)]

docker_push:
	DOCKER_TAG=$(DOCKER_TAG) bundle exec rake docker:push[$(RELEASE_PACKAGE)]

docker_push_rc:
	# push as :rc tag, the :rc is always the latest tagged release
	DOCKER_TAG=rc bundle exec rake docker:push[$(RELEASE_PACKAGE)]

docker_push_latest:
	# push as :latest tag, the :latest is always the latest stable release
	DOCKER_TAG=latest bundle exec rake docker:push[$(RELEASE_PACKAGE)]

do_docker_master: RELEASE_BUCKET=omnibus-builds
do_docker_master: docker_build
ifdef NIGHTLY
do_docker_master: RELEASE_BUCKET=omnibus-builds
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

sync:
	aws s3 sync pkg/ s3://${RELEASE_BUCKET} --acl public-read --region ${RELEASE_BUCKET_REGION}
	# empty line for aws status crud
	# Replace FQDN in URL and deal with URL encoding
	echo "Download URLS:" && find pkg -type f | sed -e "s|pkg|https://${RELEASE_BUCKET}.s3.amazonaws.com|" -e "s|+|%2B|"

packagecloud:
	bash support/packagecloud_upload.sh ${PACKAGECLOUD_USER} ${PACKAGECLOUD_REPO} ${PACKAGECLOUD_OS}

do_aws_latest:
	bundle exec rake aws:process

do_aws_not_latest:
	echo "Not latest version. Nothing to do"

ifeq ($(shell git describe --exact-match --match ${LATEST_STABLE_TAG} > /dev/null 2>&1; echo $$?), 0)
aws: do_aws_latest
else
aws: do_aws_not_latest
endif

## QA related stuff
qa_docker_cleanup:
	-bundle exec rake docker:clean_qa[$(RELEASE_VERSION)]

qa_docker_build: qa_docker_cleanup
	bundle exec rake docker:build_qa[$(RELEASE_PACKAGE)]

qa_docker_push:
	DOCKER_TAG=$(DOCKER_TAG) bundle exec rake docker:push_qa[$(RELEASE_PACKAGE)]

qa_docker_push_rc:
	# push as :rc tag, the :rc is always the latest tagged release
	DOCKER_TAG=rc bundle exec rake docker:push_qa[$(RELEASE_PACKAGE)]

qa_docker_push_latest:
	# push as :latest tag, the :latest is always the latest stable release
	DOCKER_TAG=latest bundle exec rake docker:push_qa[$(RELEASE_PACKAGE)]

do_qa_docker_master: qa_docker_build
ifdef NIGHTLY
do_qa_docker_master: qa_docker_build qa_docker_push
endif

do_qa_docker_release: no_changes on_tag qa_docker_build qa_docker_push
# The rc should always be the latest tag, stable or upcoming release
ifeq ($(shell git describe --exact-match --match ${LATEST_TAG} > /dev/null 2>&1; echo $$?), 0)
do_qa_docker_release: qa_docker_push_rc
endif
# The lastest tag is alwasy the latest stable
ifeq ($(shell git describe --exact-match --match ${LATEST_STABLE_TAG} > /dev/null 2>&1; echo $$?), 0)
do_qa_docker_release: qa_docker_push_latest
endif
