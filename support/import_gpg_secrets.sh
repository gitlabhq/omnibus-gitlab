#!/bin/bash
# GPG key for package signing
if [ -n "$SECRET_AWS_ACCESS_KEY_ID" ]; then
  echo -e "[default]\naws_access_key_id = $AWS_ACCESS_KEY_ID \naws_secret_access_key = $AWS_SECRET_ACCESS_KEY" > ~/.aws/config
  AWS_ACCESS_KEY_ID="$SECRET_AWS_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$SECRET_AWS_SECRET_ACCESS_KEY" aws s3 cp s3://omnibus-sig/package.sig.key .
  gpg --batch --no-tty --allow-secret-key-import --import package.sig.key
  rm package.sig.key
else
  echo "No GPG secret key were imported."
fi
