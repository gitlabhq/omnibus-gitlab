use_s3_caching Gitlab::Util.get_env('USE_S3_CACHE') || false
s3_access_key Gitlab::Util.get_env('CACHE_AWS_ACCESS_KEY_ID')
s3_secret_key Gitlab::Util.get_env('CACHE_AWS_SECRET_ACCESS_KEY')
s3_bucket Gitlab::Util.get_env('CACHE_AWS_BUCKET')
s3_region Gitlab::Util.get_env('CACHE_AWS_S3_REGION')
s3_accelerate Gitlab::Util.get_env('CACHE_S3_ACCELERATE') || false

build_retries 2
fetcher_retries 5
append_timestamp false
