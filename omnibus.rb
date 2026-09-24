use_s3_caching !ENV['USE_S3_CACHE'].nil? && !ENV['USE_S3_CACHE'].casecmp("false").zero?
s3_access_key ENV['CACHE_AWS_ACCESS_KEY_ID']
s3_secret_key ENV['CACHE_AWS_SECRET_ACCESS_KEY']
s3_bucket ENV['CACHE_AWS_BUCKET']
s3_region ENV['CACHE_AWS_S3_REGION']
s3_endpoint ENV['CACHE_AWS_S3_ENDPOINT']
s3_accelerate !ENV['CACHE_S3_ACCELERATE'].nil? && !ENV['CACHE_S3_ACCELERATE'].casecmp("false").zero?
fetch_workers ENV['OMNIBUS_FETCH_WORKERS_COUNT'].to_i if ENV['OMNIBUS_FETCH_WORKERS_COUNT']

build_retries 2
fetcher_retries 5
fetcher_progress_bar false
append_timestamp false

# Single point of control for Go FIPS builds: every Go component inherits
# GOFIPS140 from the process environment, instead of each software definition
# remembering to set it. A component opts out only by setting it to 'off'.
# The check then stops such a build at config load when the builder image's
# toolchain cannot deliver the module.
# See doc/development/new-software-definition.md.
require File.expand_path('lib/gitlab/build/check', __dir__)
Build::Check.export_go_fips_module_env!
Build::Check.verify_go_fips_toolchain!
