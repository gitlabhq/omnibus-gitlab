---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Adding a new software definition
---

In order to add a new component to GitLab, you should follow these steps:

1. [Fetch and compile the software during build](#fetch-and-compile-the-software-during-build)
1. [Add a dependency for the software definition to another component](#add-a-dependency-for-the-software-definition-to-another-component)

## Fetch and compile the software during build

[Software Definitions](architecture/_index.md#software-definitions), which
can be found in `/config/software`, specify where the Linux package should fetch the
software, how to compile it and install it to the required folder. This part of
the project is run when we build the Linux package for GitLab.

When adding a component that should be fetched from Git the clone address of the
repositories of the local mirror and upstream should be added to
`/.custom_sources.yml`.

The local mirror should be created in the [`omnibus-mirror` project](omnibus-mirror.md) by a member of the Distribution team.

See other Software services in the directory for examples on how to include your
software service.

## Handling Licenses

Most software repositories include a license file. Add the license using a patch
file if it is not explicitly included. Software installed using a package manager
such as `gem` or `pip` should also use this method.

[Create patches](creating-patches.md) for licenses added manually and store them
at a directory path with the naming convention
`config/patches/SOFTWARE_NAME/license/VERSION_NUMBER/add-license-file.patch`.

> Licenses can and do change over the lifetime of a project. This method
> intentionally causes builds to fail reminding contributors to verify manually
> installed licenses. If the license has not changed then `git mv` the `VERSION_NUMBER`
> directory containing the patch file to the new `VERSION_NUMBER`.

## Add a dependency for the software definition to another component

Add a `dependency` statement to the definition of the GitLab project found in
`/config/projects/gitlab.rb`, unless there is a more specific component it makes
sense to be a dependency of (eg `config/software/gitlab-rails.rb` for a
component only needed by `gitlab-rails`)

Omnibus will build dependency components first, and then other ones in the order
of their presence in `/config/projects/gitlab.rb`. So, when a software component
A is marked as a dependency of another software B, A will be built towards the
beginning of the process. In cases where A is a component that changes frequently, cache gets invalidated often causing every subsequent component to be
rebuilt, increasing overall build time. A workaround is to ensure A gets built
immediately before B, avoiding cache invalidation.

1. Add the software A to `/config/projects/gitlab.rb` immediately before
   software B

   Since A and B are now top-level dependencies of the project, omnibus will
   build them in the order of their presence in `/config/projects/gitlab.rb`.

1. In the software definition of B, add a line similar to the following

   ```ruby
   dependency '<name of software A>' unless project.dependencies.include?('<name of software A>')
   ```

   Above ensures that whenever the project is not built from
   `/config/projects/gitlab.rb`, A is marked as a dependency of B and is built
   before B. There will be no effect on builds from `/config/projects/gitlab.rb`
   however.

## Validating changes to a single software dependency

It can be useful to only build one piece of software, rather than rebuild the whole package each time. For instance,
when adding a new software definition. Using this method, you can quickly rebuild an omnibus package containing only
the software and its dependencies. Once you've confirmed the software builds on its own, you can add it to the Omnibus GitLab
build and confirm it there. To use this:

1. [Setup your development environment](setup.md)
1. Copy the [simple.rb](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/doc/development/examples/simple.rb) file into your projects

   ```shell
   cp doc/development/examples/simple.rb config/projects/
   ```

1. Change the `dependency` in `config/projects/simple.rb` to match the software you are testing
1. Build the simple project by running

   ```shell
   bundle exec omnibus build simple
   ```

## Go components and FIPS

Go software definitions need no FIPS wiring. When `Build::Check.use_go_fips_module?` is
true -- because `Build::Check.fips?` returns true, or `USE_GO_FIPS_MODULE=true` is set --
`omnibus.rb` calls `Build::Check.export_go_fips_module_env!` once, which exports
`GOFIPS140` into the omnibus process environment. Every build command inherits it,
because a definition's `env` hash is merged over the inherited environment rather than
replacing it.

Do not add `GOFIPS140` to a new definition. A component may only opt *out*, and only
with a justification:

```ruby
# <component> cannot use the Go Cryptographic Module because <reason>.
env['GOFIPS140'] = 'off'
```

A bypass must also be added to `bypasses` in
`spec/lib/gitlab/build/go_fips_definitions_spec.rb`, which fails the build for any
definition that sets `GOFIPS140` without one. This keeps the default FIPS-on and makes
every exception explicit and reviewable.

`omnibus.rb` also calls `Build::Check.verify_go_fips_toolchain!`. That
check stops the build at config load if the Go toolchain in the builder image cannot
supply the module, rather than letting the build produce Go binaries with standard Go
crypto and report nothing.

A component whose upstream build system has its own FIPS switch still sets that switch
in its definition, gated on the same `Build::Check.use_go_fips_module?`. `FIPS_MODE=1`
is the convention across the GitLab Go projects: it adds the `fips` build
tag, which selects the real implementation in `labkit/fips`. The build tag
and `GOFIPS140` are independent. `GOFIPS140` selects the cryptographic module, and
the tag decides whether the component's own FIPS-conditional code compiles in.

`FIPS_MODE` is a convention, not a rule. Check what the component's build system
reads. The `registry` takes `BUILDTAGS`, which its Makefile passes to `go build -tags`,
so `registry.rb` appends `fips` there instead.

Adding the tag also requires a labkit new enough to build without `crypto/boring`.
A component that sets the `fips` tag compiles the `//go:build fips` files of
`labkit/fips`. Before labkit `v1.64.10`, those files import `crypto/boring`, which has
no buildable files under upstream Go, and the build fails with `build constraints
exclude all Go files`. From `v1.64.10`, labkit puts that probe behind
`fips && boringcrypto`, so the tag compiles against the Go Cryptographic Module.
A component pinned below that version still gets `GOFIPS140`, but it compiles the
`//go:build !fips` stub and reports FIPS as off at run time. Check the labkit version
of the component before you add the tag.

Gate that switch on the concerns it actually drives for that component:

- Go-only components, such as `gitlab-shell.rb`, `gitlab-kas.rb` and `gitlab-pages.rb`, gate
  `FIPS_MODE=1` on `Build::Check.use_go_fips_module?`.
- `git.rb` runs only Git targets, where `FIPS_MODE=1` does nothing but select the OpenSSL
  SHA256 backend for the C build. It gates on `Build::Check.use_system_ssl?`.
- `gitaly.rb` builds both. In Gitaly's Makefile, `FIPS_MODE` adds the `fips` Go build tag and
  sets `-Dsha256_backend=openssl` for the bundled Git C build, and upstream offers no way to
  request one without the other. It therefore gates on either check being true.
