use_s3_caching ENV['USE_S3_CACHE'] || false
s3_access_key ENV['CACHE_AWS_ACCESS_KEY_ID']
s3_secret_key ENV['CACHE_AWS_SECRET_ACCESS_KEY']
s3_bucket ENV['CACHE_AWS_BUCKET']
s3_region ENV['CACHE_AWS_S3_REGION']

build_retries 2
fetcher_retries 5
append_timestamp false
