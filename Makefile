PROJECT=gitlab
RELEASE_BUCKET=downloads-packages
RELEASE_BUCKET_REGION=eu-west-1
SECRET_DIR:=$(shell openssl rand -hex 20)
PLATFORM_DIR:=$(shell bundle exec support/ohai-helper platform-dir)
PACKAGECLOUD_USER=gitlab
PACKAGECLOUD_REPO:=$(shell support/repo_name.sh)
PACKAGECLOUD_OS:=$(shell bundle exec support/ohai-helper repo-string)

build:
	bin/omnibus build ${PROJECT} --override append_timestamp:false --log-level info

# No need to suppress timestamps on the test builds
test_build:
	bin/omnibus build ${PROJECT} --log-level info

# If this task were called 'release', running 'make release' would confuse Make
# because there exists a file called 'release.sh' in this directory. Make has
# built-in rules on how to build .sh files. By calling this task do_release, it
# can coexist with the release.sh file.
do_release: no_changes on_tag purge build move_to_platform_dir sync packagecloud

# Redefine RELEASE_BUCKET for test builds
test: RELEASE_BUCKET=omnibus-builds
test: no_changes purge test_build move_to_platform_dir sync

# Redefine PLATFORM_DIR for Raspberry Pi 2 packages. Do not sync to packagecloud
do_rpi2_release: PLATFORM_DIR=raspberry-pi
do_rpi2_release: no_changes purge test_build move_to_platform_dir sync

no_changes:
	git diff --quiet HEAD

on_tag:
	git describe --exact-match

purge:
	# Force a new clone of gitlab-rails because we change remotes for CE/EE
	rm -rf /var/cache/omnibus/src/gitlab-rails
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

sync: move_to_secret_dir md5 s3_sync

move_to_secret_dir:
	if support/is_gitlab_ee.sh ; then \
	  mv pkg ${SECRET_DIR} \
	  && mkdir pkg \
	  && mv ${SECRET_DIR} pkg/ \
	  ; fi

md5:
	find pkg -name '*.json' -exec cat {} \;

s3_sync:
	aws s3 sync pkg/ s3://${RELEASE_BUCKET} --acl public-read --region ${RELEASE_BUCKET_REGION}
	# empty line for aws status crud
	# Download URLS:
	find pkg -type f | sed "s|pkg|https://${RELEASE_BUCKET}.s3.amazonaws.com|"

packagecloud:
	# - We set LC_ALL below because package_cloud is picky about the locale
	LC_ALL='en_US.UTF-8' bin/package_cloud push ${PACKAGECLOUD_USER}/${PACKAGECLOUD_REPO}/${PACKAGECLOUD_OS} $(shell find pkg -name '*.rpm' -or -name '*.deb')
