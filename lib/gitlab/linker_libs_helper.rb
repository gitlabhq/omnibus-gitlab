require_relative 'linker_helper'

# Resolves a package's allowed library set and its pkg-config files
# via `LinkerHelper`. Instantiate with three keyword arguments:
#
#   base_libs:            -- Array of soname-prefix strings to seed
#                            the linker walk (e.g. %w[libssl libcrypto]).
#   pkg_config_files:     -- Hash that maps pkg-config filenames to
#                            their resolved paths (nil until resolved).
#   pkg_config_threshold: -- Integer minimum count of resolved entries
#                            required for `pkg_config_files?` to return
#                            true.
#
# Each consumer keeps its own `cmake_flags` because the formula varies
# per package.
class LinkerLibsHelper
  def initialize(base_libs:, pkg_config_files:, pkg_config_threshold:)
    @base_libs = base_libs
    @pkg_config_files = pkg_config_files
    @pkg_config_threshold = pkg_config_threshold
  end

  def allowed_libs
    @allowed_libs ||= begin
      deps = []
      @base_libs.each do |lib|
        find_deps(lib, deps)
      end

      deps.map { |dep| File.basename(dep).split(".so").first }.uniq
    end
  end

  def find_libs(name)
    LinkerHelper.ldconfig.select { |lib| lib.start_with?(name) }
  end

  def pkg_config_files
    return @pkg_config_files.compact if pkg_config_files?

    system_pkg_config_dirs.each do |pkg_config_dir|
      break if pkg_config_files?

      @pkg_config_files.each do |filename, filepath|
        next unless filepath.nil?

        file_path = File.expand_path(filename, pkg_config_dir)
        @pkg_config_files[filename] = file_path if File.exist? file_path
      end
    end

    @pkg_config_files.compact
  end

  def pkg_config_dirs
    @pkg_config_dirs ||= pkg_config_files.values.map { |f| File.dirname(f) }.uniq.join(":")
  end

  private

  def append_deps(path, deps)
    return if path.start_with?("/opt/gitlab") || !path.start_with?("/")

    puts "\tReads dependencies of #{path}"
    items = LinkerHelper.ldd(path).values.reject { |lib| lib == "statically" }

    deps.concat(items).uniq!
  end

  def find_deps(name, deps)
    puts "Libraries that start with '#{name}' and their dependencies"
    deps << name
    start = deps.length
    libs = find_libs(name)

    libs.each do |lib, path|
      append_deps(path, deps)
    end

    cursor = start

    loop do
      break if cursor >= deps.length

      append_deps(deps[cursor], deps)
      cursor += 1
    end
  end

  def pkg_config_files?
    @pkg_config_files.values.compact.length >= @pkg_config_threshold
  end

  def system_pkg_config_dirs
    @system_pkg_config_dirs ||= IO.popen(%w[pkg-config --variable pc_path pkg-config], &:read)&.split(":")&.map(&:strip)
  end
end
