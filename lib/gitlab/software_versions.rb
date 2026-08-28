require 'date'
require 'yaml'
require 'net/http'
require 'rubygems'
require 'uri'

require_relative 'version'

module Gitlab
  # Reads and updates config/software_versions.yml, the single source of truth
  # for pinned versions and checksums of bundled third-party components.
  #
  # Checksum fetching is pluggable per component (see #fetch_sha256), so bumping
  # a component becomes a data-only change driven by `rake software_versions:*`
  # instead of hand-editing Ruby build logic.
  class SoftwareVersions
    RUBY_RELEASES_URL = 'https://raw.githubusercontent.com/ruby/www.ruby-lang.org/master/_data/releases.yml'.freeze

    # A sha256 digest is exactly 64 lowercase hex characters.
    SHA256_REGEX = /\A[0-9a-f]{64}\z/

    def initialize(path = Gitlab::Version.software_versions_path)
      @path = path
      # Load with scalars kept as Strings so versions are never coerced to floats.
      @data = Gitlab::Version.load_versions_file(path)
    end

    attr_reader :data

    # Pin +component+ to +version+, fetching the source tarball sha256 from
    # upstream unless one is supplied. Rewrites the file and returns the sha256.
    #
    # For components with a `checksums` map (e.g. ruby) the new version is added
    # to the map and becomes the `next` pin; otherwise `version`/`sha256` are
    # replaced.
    def update(component, version, sha256: nil)
      entry = data.fetch(component) { raise KeyError, "Unknown component '#{component}' in #{@path}" }

      # A single checksum would silently drop the other architectures' pins.
      if entry['sha256'].is_a?(Hash)
        raise ArgumentError,
              "'#{component}' pins one sha256 per architecture; update the map in #{@path} by hand"
      end

      sha256 ||= fetch_sha256(component, version)
      validate_sha256!("#{component} #{version}", sha256)

      if entry.key?('checksums')
        entry['checksums'][version] = sha256
        # Only promote to the `next` pin when the version is actually newer than
        # the current one; recording a checksum for a patch in the current
        # series (e.g. adding 3.3.12 while next is 3.4.9) must not move `next`.
        newer_than_next = entry.key?('next') && Gem::Version.new(version) > Gem::Version.new(entry['next'])
        entry['next'] = version if newer_than_next
      else
        entry['version'] = version
        entry['sha256'] = sha256
      end

      save
      sha256
    end

    # Verify that pinned checksums still match upstream, for every component
    # that has a fetcher. Returns an array of human-readable mismatch strings
    # (empty when everything matches).
    def verify
      mismatches = []

      pinned_checksums.each do |component, version, pinned|
        actual = begin
          fetch_sha256(component, version)
        rescue NotImplementedError
          next # no fetcher for this component; nothing to verify
        end

        mismatches << "#{component} #{version}: pinned #{pinned}, upstream #{actual}" if actual != pinned
      end

      mismatches
    end

    # Every stored checksum (source and UBT bundle) that is not a well-formed
    # sha256. Returns an array of human-readable descriptions, empty when all
    # are valid.
    def malformed_checksums
      problems = []

      each_stored_checksum do |label, sha|
        problems << "#{label}: '#{sha}' is not a valid sha256" unless sha.to_s.match?(SHA256_REGEX)
      end

      problems
    end

    # Fetch the sha256 of a component's upstream source tarball.
    def fetch_sha256(component, version)
      case component
      when 'ruby'
        fetch_ruby_sha256(version)
      else
        raise NotImplementedError, "No sha256 fetcher for '#{component}'; pass sha256: explicitly"
      end
    end

    # +releases+ is injectable for testing without network access.
    def fetch_ruby_sha256(version, releases: ruby_releases)
      release = releases.find { |r| r['version'] == version }
      raise "Ruby #{version} not found at #{RUBY_RELEASES_URL}" unless release

      release.dig('sha256', 'gz') || raise("No .tar.gz sha256 for Ruby #{version} upstream")
    end

    private

    def validate_sha256!(label, sha256)
      return if sha256.to_s.match?(SHA256_REGEX)

      raise ArgumentError, "Invalid sha256 for #{label}: #{sha256.inspect} (expected 64 hex characters)"
    end

    # Yields [label, sha256] for every checksum stored for any component: each
    # `checksums` entry, each architecture of a per-architecture `sha256` map
    # (e.g. glaz-ffi), or the single `sha256`, plus the `ubt` bundle checksum.
    def each_stored_checksum
      data.each do |component, entry|
        if entry['checksums']
          entry['checksums'].each { |version, sha| yield "#{component} #{version}", sha }
        elsif entry['sha256'].is_a?(Hash)
          entry['sha256'].each { |arch, sha| yield "#{component} #{entry['version']} #{arch}", sha }
        elsif entry['sha256']
          yield "#{component} #{entry['version']}", entry['sha256']
        end

        yield "#{component} ubt", entry.dig('ubt', 'sha256') if entry['ubt']
      end
    end

    # Yields [component, version, sha256] for each pinned checksum, flattening
    # both single-version and `checksums`-map components.
    def pinned_checksums
      return enum_for(:pinned_checksums) unless block_given?

      data.each do |component, entry|
        if entry['checksums']
          [entry['current'], entry['next']].compact.uniq.each do |version|
            yield component, version, entry['checksums'][version]
          end
        elsif entry['version']
          yield component, entry['version'], entry['sha256']
        end
      end
    end

    def ruby_releases
      # releases.yml carries `date:` fields, so Date must be permitted.
      YAML.safe_load(http_get(RUBY_RELEASES_URL), permitted_classes: [Date])
    end

    def http_get(url, redirect_limit = 5)
      raise "Too many HTTP redirects fetching #{url}" if redirect_limit <= 0

      response = Net::HTTP.get_response(URI(url))

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        http_get(response['location'], redirect_limit - 1)
      else
        raise "GET #{url} failed: #{response.code} #{response.message}"
      end
    end

    # Rewrites the file, preserving the leading comment/header block (everything
    # up to and including the first `---` document marker) and re-dumping the
    # data below it. Hashes preserve insertion order and YAML.dump is idempotent,
    # so an `update` touches only the lines it changes. Comments and blank lines
    # *within* the data body are not preserved, so keep all commentary in the
    # header block above `---`.
    def save
      header = File.read(@path)[/\A.*?^---\n/m] || ""
      body = YAML.dump(@data).delete_prefix("---\n")
      File.write(@path, header + body)
    end
  end
end
