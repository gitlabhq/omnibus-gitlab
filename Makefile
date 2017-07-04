RELEASE_BUCKET=downloads-packages
RELEASE_BUCKET_REGION=eu-west-1
PLATFORM_DIR:=$(shell bundle exec support/ohai-helper platform-dir)
PACKAGECLOUD_USER=gitlab
PACKAGECLOUD_OS:=$(shell bundle exec support/ohai-helper repo-string)
LATEST_STABLE_TAG:=$(shell bundle exec rake build:docker:latest_stable_tag) # TODO, remove when aws and qa are in the rake task
LATEST_TAG:=$(shell bundle exec rake build:docker:latest_tag) # TODO, remove when qa is in the rake task

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
do_release: no_changes on_tag purge build license_check move_to_platform_dir sync

# Redefine RELEASE_BUCKET for test builds
test: RELEASE_BUCKET=omnibus-builds
test: no_changes purge build license_check move_to_platform_dir sync

test_no_sync: no_changes purge build license_check move_to_platform_dir

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

docker_trigger_build_and_push:
	bundle exec rake docker:build:image
	# While triggering from omnibus repo in .com, we explicitly pass IMAGE_TAG
	# variable, which will be used to tag the final Docker image.
	# So, if IMAGE_TAG variable is empty, it means the trigger happened from
	# either CE or EE repository. In that case, we can use the GITLAB_VERSION
	# variable as IMAGE_TAG.
	if [ -z "$(IMAGE_TAG)" ] ; then export IMAGE_TAG=$(GITLAB_VERSION) ;  fi
	DOCKER_TAG=$(IMAGE_TAG) bundle exec rake docker:push:triggered

sync:
	aws s3 sync pkg/ s3://${RELEASE_BUCKET} --acl public-read --region ${RELEASE_BUCKET_REGION}
	# empty line for aws status crud
	# Replace FQDN in URL and deal with URL encoding
	echo "Download URLS:" && find pkg -type f | sed -e "s|pkg|https://${RELEASE_BUCKET}.s3.amazonaws.com|" -e "s|+|%2B|"

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
qa_docker_build:
	bundle exec rake docker:build:qa

qa_docker_push:
	bundle exec rake docker:push:qa

qa_docker_push_rc:
	# push as :rc tag, the :rc is always the latest tagged release
	DOCKER_TAG=rc bundle exec rake docker:push:qa

qa_docker_push_latest:
	# push as :latest tag, the :latest is always the latest stable release
	DOCKER_TAG=latest bundle exec rake docker:push:qa

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
