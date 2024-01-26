#!/bin/bash
# GPG key for package signing
if [ -n "$PACKAGE_SIGNING_KEY_FILE" ]; then
  gpg --batch --no-tty --allow-secret-key-import --import "$PACKAGE_SIGNING_KEY_FILE"
else
  echo "No GPG secret key were imported."
fi
