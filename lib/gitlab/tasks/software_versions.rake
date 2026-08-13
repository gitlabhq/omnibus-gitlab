require_relative '../software_versions'

namespace :software_versions do
  desc "Pin a bundled component to a version, fetching its checksum (e.g. rake 'software_versions:update[ruby,3.4.10]')"
  task :update, [:component, :version, :sha256] do |_t, args|
    raise "Usage: rake 'software_versions:update[component,version]'" unless args.component && args.version

    versions = Gitlab::SoftwareVersions.new
    sha256 = versions.update(args.component, args.version, sha256: args.sha256)

    puts "Pinned #{args.component} to #{args.version} (sha256: #{sha256})"
    puts "Review the change in #{Gitlab::Version::SOFTWARE_VERSIONS_FILENAME} and commit it."
  end

  desc "Verify pinned component checksums are well-formed and match upstream"
  task :verify do
    versions = Gitlab::SoftwareVersions.new
    problems = versions.malformed_checksums + versions.verify

    if problems.empty?
      puts "All pinned checksums are valid and match upstream."
    else
      puts "Checksum problems found:"
      problems.each { |p| puts "  - #{p}" }
      abort
    end
  end
end
