PROJECT=gitlab
RELEASE_BUCKET=downloads-packages
RELEASE_BUCKET_REGION=eu-west-1
SECRET_DIR:=$(shell openssl rand -hex 20)

build:
	OMNIBUS_APPEND_TIMESTAMP=0 bin/omnibus build project ${PROJECT}

release: no_changes on_tag purge build sync

no_changes:
	git diff --quiet HEAD

on_tag:
	git describe --exact-match

purge:
	bin/omnibus clean --purge ${PROJECT}
	mkdir -p pkg
	(cd pkg && find . -delete)

sync: remove_json move_ee_to_secret_dir md5 s3_sync

remove_json:
	find pkg/ -name '*.json' -delete

move_ee_to_secret_dir:
	if support/is_gitlab_ee.sh ; then \
	  mv pkg ${SECRET_DIR} \
	  && mkdir pkg \
	  && mv ${SECRET_DIR} pkg/ \
	  ; fi

md5:
	find pkg -type f -exec md5sum {} \;

s3_sync:
	aws s3 sync pkg/ s3://${RELEASE_BUCKET} --acl public-read --region ${RELEASE_BUCKET_REGION}
