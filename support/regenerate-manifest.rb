#!/usr/bin/env ruby
# frozen_string_literal: true

# Regenerate (and upload) the omnibus-gitlab version manifest for a single
# release tag. Handles CE vs EE automatically based on the tag.
#
# Intended to be run inside the Omnibus builder image, e.g.:
#
#   docker run -it --rm \
#     -e LICENSE_S3_BUCKET=<YOUR_BUCKET> \
#     -e LICENSE_AWS_ACCESS_KEY_ID=... \
#     -e LICENSE_AWS_SECRET_ACCESS_KEY=... \
#     -e GITLAB_TOKEN=glpat-...            `# optional` \
#     -v "$PWD/regenerate-manifest.rb:/regenerate-manifest.rb" \
#     registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/ubuntu_22.04:5.60.2 \
#     ruby /regenerate-manifest.rb 19.0.5+ee.0
#
# It performs the equivalent of:
#   git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git
#   git checkout <tag>
#   export ee=true|<unset>            # derived from the tag
#   <configure gitlab.com auth from GITLAB_TOKEN, or CI_JOB_TOKEN on gitlab.com>
#   bundle install
#   bundle exec rake manifest:upload
#
# Unlike the rake task, every shell step here is checked -- a failed clone,
# bundle, or `aws s3 sync` aborts with a non-zero exit instead of passing
# silently.
#
# By default it refuses to replace a manifest that already exists in the bucket
# (it sets MANIFEST_OVERWRITE=false for the rake task); pass --overwrite (or
# OVERWRITE=true) to allow replacing it.
#
# This file is designed to be copied out and run on its own, so it must stay
# self-contained (no requires beyond the standard library). The pure decision
# logic lives in ManifestRegen below so it can be unit tested; the orchestration
# that shells out only runs when the file is executed directly.

require 'English'
require 'optparse'
require 'tmpdir'
require 'fileutils'

DEFAULT_REPO_URL = 'https://gitlab.com/gitlab-org/omnibus-gitlab.git'
DEFAULT_WORK_DIR = ENV['WORK_DIR'] || '/builds/gitlab'

# Identity written into the isolated git config, matching what CI uses so
# omnibus' git cache has a committer when it first initialises.
GIT_USER_NAME  = 'GitLab Distribution Team'
GIT_USER_EMAIL = 'distribution-be@gitlab.com'

# Pure helpers, extracted so they can be unit tested without running the script.
module ManifestRegen
  module_function

  # 'ee' / 'ce' from a release tag such as 19.0.5+ee.0, or nil if undeterminable.
  def detect_edition(tag)
    return 'ee' if tag.match?(/\+ee(\.|\b)/)
    return 'ce' if tag.match?(/\+ce(\.|\b)/)

    nil
  end

  # 19.0.5+ee.0 -> 19.0.5
  def manifest_version(tag)
    tag.split('+', 2).first
  end

  # 19.0.5 -> 19.0
  def minor_version(version)
    version.split('.')[0, 2].join('.')
  end

  # The build iteration the rake task derives (Gitlab::BuildIteration): the part
  # of the tag after "+", up to any "-". 19.0.5+ee.0 -> ee.0
  def build_iteration(tag)
    (tag.split('+', 2)[1] || '').split('-', 2).first
  end

  # The version component the rake task uses in the manifest filename, i.e.
  # release_version.split("+")[0] == "<version>-<build iteration>".
  # 19.0.5+ee.0 -> 19.0.5-ee.0
  def object_version(tag)
    iteration = build_iteration(tag)
    iteration.to_s.empty? ? manifest_version(tag) : "#{manifest_version(tag)}-#{iteration}"
  end

  # The S3 key the rake task uploads to (see lib/gitlab/manifest/uploader.rb).
  # The filename is "<object_version>-<edition>", so for 19.0.5+ee.0 this is
  # gitlab-manifests/gitlab-ee/19.0/19.0.5-ee.0-ee.version-manifest.json.
  def object_key(edition:, tag:)
    "gitlab-manifests/gitlab-#{edition}/#{minor_version(manifest_version(tag))}/" \
      "#{object_version(tag)}-#{edition}.version-manifest.json"
  end

  # The rake subprocess derives the release version from ENV['CI_COMMIT_TAG']
  # whenever GITLAB_CI is set (Build::Check.on_tag?), ignoring the checkout. A CI
  # backfill job is rarely triggered by the tag it regenerates, so pin the tag
  # here to keep version detection correct.
  def ci_commit_tag_override(tag)
    { 'CI_COMMIT_TAG' => tag }
  end

  # proactiveAuth landed in git 2.46. Takes the `git --version` output so it can
  # be tested without shelling out.
  def proactive_auth_supported?(git_version_output)
    match = git_version_output[/(\d+)\.(\d+)/]
    return false unless match

    major, minor = match.split('.').map(&:to_i)
    (major > 2) || (major == 2 && minor >= 46)
  end

  # Decide how to authenticate to gitlab.com. `rake manifest:upload` clones
  # omnibus-gitlab and then runs `git ls-remote` against public component repos
  # such as https://gitlab.com/gitlab-org/gitlab.
  #
  # A CI_JOB_TOKEN is scoped to both the host that issued it AND the project it
  # belongs to. The earlier breakage was a dev.gitlab.org pipeline whose
  # proactiveAuth forced its dev CI_JOB_TOKEN onto
  # `git ls-remote https://gitlab.com/gitlab-org/gitlab`, which gitlab.com
  # rejected. And even on gitlab.com, the omnibus-gitlab job token is not
  # necessarily authorized for gitlab-org/gitlab. So we must never force a job
  # token onto the component lookups.
  #
  #   * GITLAB_TOKEN (a human gitlab.com PAT) can read every public repo, so we
  #     authenticate all of https://gitlab.com with it -- the clone and the
  #     component lookups -- for the higher authenticated rate limit.
  #   * CI_JOB_TOKEN is applied path-scoped to the omnibus-gitlab clone only, and
  #     only when the pipeline runs on gitlab.com. Component lookups stay
  #     anonymous (the repos are public), so a project-scoped job token is never
  #     sent to gitlab-org/gitlab.
  #   * Anything else clones anonymously (returns nil).
  #
  # `env` is anything responding to [] (ENV or a test hash). Returns a Hash with
  # :user, :secret_var, :cred_scope, :http_scope, :reason, or nil for anonymous.
  def gitlab_com_auth(env, repo_url)
    clone_url = repo_url.delete_suffix('.git')

    if present?(env['GITLAB_TOKEN'])
      { user: 'oauth2', secret_var: 'GITLAB_TOKEN',
        cred_scope: 'https://gitlab.com', http_scope: 'https://gitlab.com',
        reason: 'GITLAB_TOKEN (all of gitlab.com)' }
    elsif present?(env['CI_JOB_TOKEN']) && env['CI_SERVER_HOST'] == 'gitlab.com' &&
        clone_url.start_with?('https://gitlab.com/')
      { user: 'gitlab-ci-token', secret_var: 'CI_JOB_TOKEN',
        cred_scope: clone_url, http_scope: "#{clone_url}.git",
        reason: "CI_JOB_TOKEN (scoped to #{clone_url})" }
    end
  end

  def present?(value)
    !(value || '').strip.empty?
  end
end

# :nocov:
# Everything below shells out to git/bundle/rake/aws. It is exercised by running
# the script, not by the unit tests, so it is excluded from coverage.

def run!(*cmd, chdir: Dir.pwd)
  printf("+ (%s) %s\n", chdir, cmd.join(' '))
  # system returns nil (and $CHILD_STATUS may be nil) when the executable
  # can't be spawned.
  ok = system(*cmd, chdir: chdir)
  return if ok

  abort("error: command failed (exit #{$CHILD_STATUS&.exitstatus || 'unknown'}): #{cmd.join(' ')}")
end

def capture(*cmd, chdir: Dir.pwd)
  # stderr is merged into stdout so it shows up in the abort message below.
  out = IO.popen(cmd, chdir: chdir, err: [:child, :out], &:read).strip
  return out if $CHILD_STATUS&.success?

  abort("error: command failed (exit #{$CHILD_STATUS&.exitstatus || 'unknown'}): #{cmd.join(' ')}\n#{out}")
rescue Errno::ENOENT => e
  # Unlike system (used by run!), IO.popen raises if the executable is missing;
  # translate it to the same clean abort the rest of the script relies on.
  abort("error: could not run '#{cmd.join(' ')}': #{e.message}")
end

if $PROGRAM_NAME == __FILE__
  options = {
    repo_url: DEFAULT_REPO_URL,
    work_dir: DEFAULT_WORK_DIR,
    edition: nil, # auto-detect from the tag
    clone: true,
    bundle: true,
    # Protect existing manifests by default; OVERWRITE=true or --overwrite opts in.
    overwrite: (ENV['OVERWRITE'] || '').strip == 'true',
  }

  parser = OptionParser.new do |o|
    o.banner = <<~BANNER
      Usage: regenerate-manifest.rb [options] TAG

      Regenerate and upload the version manifest for an omnibus-gitlab release
      tag (e.g. 19.0.5+ee.0 or 19.0.5+ce.0).

      Environment:
        LICENSE_S3_BUCKET             (required) target bucket for the manifest
        LICENSE_S3_BUCKET_REGION      (optional) bucket region (default: eu-west-1)
        LICENSE_AWS_ACCESS_KEY_ID     (required to actually upload)
        LICENSE_AWS_SECRET_ACCESS_KEY (required to actually upload)
        GITLAB_TOKEN                  (optional) gitlab.com PAT enabling proactive
                                      auth to gitlab.com for a higher rate limit
        CI_JOB_TOKEN                  (CI) authenticates the omnibus-gitlab clone
                                      only, and only when CI_SERVER_HOST ==
                                      gitlab.com; component lookups stay anonymous
        OVERWRITE                     (optional) set to "true" to replace an
                                      existing manifest (same as --overwrite)

      Options:
    BANNER

    o.on('--repo-url URL', "Repo to clone (default: #{DEFAULT_REPO_URL})") { |v| options[:repo_url] = v }
    o.on('--work-dir DIR', "Working directory (default: #{DEFAULT_WORK_DIR})") { |v| options[:work_dir] = v }
    o.on('--edition EDITION', %w[ce ee], 'Force edition (ce|ee); default: derive from tag') { |v| options[:edition] = v }
    o.on('--[no-]clone', 'Clone/fetch the repo (default: yes). Use --no-clone to reuse WORK_DIR/omnibus-gitlab') { |v| options[:clone] = v }
    o.on('--[no-]bundle', 'Run bundle install (default: yes)') { |v| options[:bundle] = v }
    o.on('--overwrite', 'Replace an existing manifest for this tag (default: refuse if one exists)') { options[:overwrite] = true }
    o.on('-h', '--help', 'Show this help') do
      puts o
      exit
    end
  end
  parser.parse!

  tag = ARGV.shift
  if tag.nil? || tag.empty?
    warn parser.to_s
    exit 1
  end

  # --- resolve edition -----------------------------------------------------

  edition = options[:edition] || ManifestRegen.detect_edition(tag)
  abort("error: could not determine edition from tag '#{tag}'. Pass --edition ce|ee.") if edition.nil?

  if edition == 'ee'
    ENV['ee'] = 'true'
  else
    # is_ee? also inspects `ee`, GITLAB_VERSION, and the tag's VERSION file, so
    # clear any inherited value that could force EE on a CE tag.
    ENV.delete('ee')
    ENV.delete('GITLAB_VERSION')
  end

  # Tell `rake manifest:upload` whether it may replace an existing manifest. The
  # script protects by default (MANIFEST_OVERWRITE=false); --overwrite lets the
  # rake task clobber a manifest that already exists in the bucket.
  ENV['MANIFEST_OVERWRITE'] = options[:overwrite] ? 'true' : 'false'

  # Build::Check.on_tag? trusts ENV['CI_COMMIT_TAG'] over the checkout whenever
  # GITLAB_CI is set, and a backfill job is rarely triggered by the tag it
  # regenerates. Pin it to the requested tag so the rake subprocess derives the
  # right version; warn when this actually overrides an inherited value.
  inherited_tag = ENV['CI_COMMIT_TAG']
  if ManifestRegen.present?(inherited_tag) && inherited_tag != tag
    warn(">> CI_COMMIT_TAG=#{inherited_tag} does not match #{tag}; overriding it for " \
         'version detection.')
  end
  ManifestRegen.ci_commit_tag_override(tag).each { |key, value| ENV[key] = value }

  # --- pre-flight checks ---------------------------------------------------

  abort('error: LICENSE_S3_BUCKET is required (the rake task reads it to build the manifest path).') if (ENV['LICENSE_S3_BUCKET'] || '').strip.empty?

  # The rake task shells out to `aws s3 sync` with system(), which returns nil
  # silently when the executable is missing, so a fetch and upload become no-ops
  # and the run still reports success. Fail fast here, before cloning and
  # bundling. (This check lives in the script, not lib/, because regenerating an
  # old tag runs that tag's copy of lib/.)
  abort('error: aws CLI not found on PATH; install awscli (the builder image includes it).') \
    unless system('aws', '--version', out: File::NULL, err: File::NULL)

  license_aws_creds = !(ENV['LICENSE_AWS_ACCESS_KEY_ID'] || '').strip.empty? &&
    !(ENV['LICENSE_AWS_SECRET_ACCESS_KEY'] || '').strip.empty?
  unless license_aws_creds
    warn('NOTE: LICENSE_AWS_ACCESS_KEY_ID / LICENSE_AWS_SECRET_ACCESS_KEY not set.')
    warn('      The rake task clears those two env vars for the `aws` subprocess,')
    warn('      so the AWS CLI will fall back to the rest of its credential chain')
    warn('      (IAM instance/ECS role, AWS_PROFILE, SSO, ~/.aws/credentials). The')
    warn('      upload can still succeed via one of those; if none are available it')
    warn('      fails silently (the rake task ignores the aws exit code). Verify the')
    warn('      object afterwards to be sure.')
  end

  warn("WARNING: '#{tag}' looks like an RC tag; manifest:upload is a no-op for RC tags.") if tag.include?('rc')

  auth = ManifestRegen.gitlab_com_auth(ENV, options[:repo_url])
  if auth && !ManifestRegen.proactive_auth_supported?(capture('git', '--version'))
    warn('WARNING: git < 2.46 does not support http.proactiveAuth; proactive auth')
    warn('         will be ignored (clones still work, just without it).')
  end

  # --- isolated git config -------------------------------------------------
  #
  # Point GIT_CONFIG_GLOBAL at a throwaway file so we never touch the caller's
  # ~/.gitconfig. Every git invocation below -- including those omnibus spawns
  # during `rake manifest:upload` -- reads it.

  git_config = File.join(Dir.mktmpdir('manifest-gitconfig'), 'gitconfig')
  ENV['GIT_CONFIG_GLOBAL'] = git_config

  File.write(git_config, <<~CFG)
    [user]
        name = #{GIT_USER_NAME}
        email = #{GIT_USER_EMAIL}
  CFG

  if auth
    # The helper references the secret as ${VAR} so the shell expands it at auth
    # time; the token itself never lands on disk. #{auth[:secret_var]} (the env
    # var NAME) is interpolated by Ruby; \\" keeps the inner quotes literal.
    File.write(git_config, <<~CFG, mode: 'a')
      [credential "#{auth[:cred_scope]}"]
          helper = "!f() { echo username=#{auth[:user]}; echo \\"password=${#{auth[:secret_var]}}\\"; }; f"
      [http "#{auth[:http_scope]}"]
          proactiveAuth = basic
    CFG
    puts ">> Authenticating with #{auth[:reason]}; proactive Basic auth enabled."
  else
    puts '>> No usable gitlab.com token: clones will be anonymous.'
    if ManifestRegen.present?(ENV['CI_JOB_TOKEN']) && ENV['CI_SERVER_HOST'] != 'gitlab.com'
      puts ">>   (CI_JOB_TOKEN is set but the pipeline runs on #{ENV['CI_SERVER_HOST']}, not"
      puts '>>    gitlab.com, so it is not sent to gitlab.com.)'
    end
  end

  # --- clone / checkout ----------------------------------------------------

  repo_dir = File.join(options[:work_dir], 'omnibus-gitlab')

  # Mark repo_dir safe before any git operation touches it. When WORK_DIR is a
  # mounted host volume the existing checkout may be owned by a different uid,
  # which would otherwise make git refuse the fetch/checkout below with
  # "detected dubious ownership". Registering it up front (the path need not
  # exist yet) covers the fetch, clone, and checkout alike.
  run!('git', 'config', '--global', '--add', 'safe.directory', repo_dir)

  if options[:clone]
    FileUtils.mkdir_p(options[:work_dir])
    if File.directory?(File.join(repo_dir, '.git'))
      # Full fetch so the checkout can be reused across arbitrary tags.
      puts ">> #{repo_dir} already exists; fetching tags."
      run!('git', 'fetch', '--tags', '--prune', 'origin', chdir: repo_dir)
    else
      # A full clone (not shallow) so any tag can be checked out afterwards.
      run!('git', 'clone', options[:repo_url], repo_dir)
    end
  elsif !File.directory?(File.join(repo_dir, '.git'))
    abort("error: --no-clone given but #{repo_dir} is not a git checkout.")
  end

  run!('git', 'checkout', '--detach', tag, chdir: repo_dir)

  # Sanity check: version detection off-CI relies on `git describe --exact-match`
  # resolving to the tag. If it doesn't, release_version would be wrong and the
  # manifest would be uploaded under the wrong name -- abort rather than risk
  # clobbering a shared bucket with a mislabelled file. (capture aborts already
  # if describe itself fails; this guards the rare case of another tag on the
  # same commit winning the match.)
  described = capture('git', 'describe', '--tags', '--exact-match', chdir: repo_dir)
  if described != tag
    abort("error: 'git describe --exact-match' returned '#{described}', not '#{tag}'. " \
          'The derived version/filename would be wrong; aborting.')
  end

  version = ManifestRegen.manifest_version(tag)
  minor = ManifestRegen.minor_version(version)

  puts
  puts '================================================================'
  puts ">> tag:     #{tag}"
  puts ">> edition: #{edition}"
  puts ">> version: #{version} (minor #{minor})"
  puts ">> VERSION file: #{File.read(File.join(repo_dir, 'VERSION')).strip}"
  puts ">> repo:    #{repo_dir}"
  puts ">> bucket:  #{ENV['LICENSE_S3_BUCKET']}"
  # The rake task uploads to eu-west-1 by default (lib/gitlab/manifest/uploader.rb);
  # LICENSE_S3_BUCKET_REGION overrides it for a personal test bucket elsewhere.
  puts ">> upload region: #{ENV['LICENSE_S3_BUCKET_REGION'] || 'eu-west-1'}"
  puts ">> overwrite: #{options[:overwrite] ? 'yes' : 'no (refuse if the manifest already exists)'}"
  puts '================================================================'
  puts

  # --- build + upload ------------------------------------------------------

  run!('bundle', 'install', chdir: repo_dir) if options[:bundle]
  run!('bundle', 'exec', 'rake', 'manifest:upload', chdir: repo_dir)

  # --- summary -------------------------------------------------------------

  object_key = ManifestRegen.object_key(edition: edition, tag: tag)
  puts
  puts '>> done.'
  puts ">> expected object: s3://#{ENV['LICENSE_S3_BUCKET']}/#{object_key}"
  unless license_aws_creds
    puts '>> NOTE: LICENSE_AWS_* were not set; the upload relied on the ambient AWS'
    puts '>>       credential chain (IAM role / AWS_PROFILE / SSO / ~/.aws). Confirm'
    puts '>>       it actually landed with the command below.'
  end
  puts '>> verify with (region is auto-resolved for the bucket):'
  puts "     aws s3 ls s3://#{ENV['LICENSE_S3_BUCKET']}/#{object_key}"
end
# :nocov:
