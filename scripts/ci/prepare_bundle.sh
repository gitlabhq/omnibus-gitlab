#!/bin/env bash

gem install bundler:${BUNDLER_VERSION}
bundle config set --local path 'gems'
bundle config set --local without 'rubocop'
if [ "$INCLUDE_PACKAGECLOUD" = "true" ]; then
    bundle config set --local with 'packagecloud';
fi
# If OMNIBUS_GEM_SOURCE is set, then check it out as a local override to the
# omnibus gem. The local overide does not change the Gemfile.lock. As part of
# the build pipeline, we are checking whether the state of the repository is
# unchanged during the build process, by comparing it with the last commit
# (So that no unexpected monsters show up). So, an altered Gemfile.lock file
# would fail on this check. Using the local override avoids this. Bundler
# will still validate and use the git revision specified in the Gemfile.lock
# when using the local checkout.
if [ -n "${OMNIBUS_GEM_SOURCE}" ]; then
    git clone --branch "$(cat OMNIBUS_GEM_VERSION)" "${OMNIBUS_GEM_SOURCE}" .bundle/local-omnibus;
    bundle config --local local.omnibus .bundle/local-omnibus;
    bundle config --local disable_local_branch_check true;
fi

bundle config set frozen 'true'

echo -e "section_start:`date +%s`:bundle_install[collapsed=true]\r\e[0Kbundle install -j $(nproc)"
bundle install -j $(nproc)
echo -e "section_end:`date +%s`:bundle_install\r\e[0K"
bundle binstubs --all
