#!/bin/env bash

gem install bundler:${BUNDLER_VERSION}
bundle config set --local path 'gems'
bundle config set --local without 'rubocop'
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
# Pre-install ffi and ffi-compiler sequentially to avoid a parallel install
# race triggered by a gap in llhttp-ffi's declared dependencies.
#
# llhttp-ffi's gemspec declares ffi-compiler as a runtime dep but omits ffi
# itself. At build time, ext/Rakefile does `require 'ffi-compiler/compile_task'`
# which immediately does `require 'ffi'`. Because ffi is only a transitive dep
# (llhttp-ffi -> ffi-compiler -> ffi), bundler's parallel installer can start
# llhttp-ffi's native extension build as soon as ffi-compiler is queued, without
# waiting for ffi to finish installing, causing a load error.
gem install ffi ffi-compiler
bundle install -j $(nproc)
echo -e "section_end:`date +%s`:bundle_install\r\e[0K"
bundle binstubs --all
