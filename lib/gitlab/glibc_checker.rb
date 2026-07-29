require 'shellwords'
require 'set'

require_relative 'util'

module Gitlab
  class GlibcChecker
    # Timeout (in seconds) for individual objdump/file invocations so a
    # corrupted or unusually large binary can't hang the build indefinitely.
    SHELLOUT_TIMEOUT = 60

    # MIME types reported by `file --mime-type` for the artifacts we inspect.
    SHARED_LIBRARY_MIME_TYPE = 'application/x-sharedlib'.freeze
    EXECUTABLE_MIME_TYPES = ['application/x-executable', 'application/x-pie-executable'].freeze

    # Individual symbols that reference a newer GLIBC version than the build
    # host but are known to be safe to ignore, keyed by a pattern matching the
    # files they appear in. Only the listed symbols are discarded, so any other
    # incompatibility in the same file is still caught.
    #
    # `_dl_find_object` was introduced in GLIBC 2.35 and is referenced by
    # gRPC's C extension, but it is an optional reference that does not cause a
    # runtime failure on older GLIBC. The gem and Ruby versions in the path
    # change between builds, so the file is matched by pattern. See
    # https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9209#note_3447666399
    IGNORED_SYMBOLS_BY_PATH = {
      %r{/grpc-[^/]+/.*grpc_c\.so\z} => ['_dl_find_object']
    }.freeze

    attr_reader :issues, :max_required_version

    def self.check_all
      new.check_all
    end

    def initialize
      @install_dir = '/opt/gitlab'
      @issues = []
      @max_required_version = nil
      @files_by_version = {}
      @system_version = nil
      @symbols_by_file = {}
    end

    def check_all
      @system_version = get_system_glibc_version
      log_info "System GLIBC version: #{@system_version}"
      log_info "Scanning #{@install_dir} for .so files and binaries checking GLIBC versions..."

      so_files = find_so_files
      binaries = find_binaries
      all_files = so_files + binaries
      log_info "Found #{so_files.length} .so files and #{binaries.length} binaries"

      all_files.each do |file|
        check_file(file)
      end

      report_results
    end

    private

    def log_info(message)
      puts message
    end

    def log_error(message)
      puts message
    end

    def get_system_glibc_version
      output = Gitlab::Util.shellout_stdout('ldd --version | head -1')
      match = output&.match(/(\d+\.\d+)/)
      match ? match[1] : 'unknown'
    rescue Gitlab::Util::ShellOutExecutionError => e
      warn "Failed to get system GLIBC version: #{e.message}"
      'unknown'
    end

    def find_so_files
      Dir.glob("#{@install_dir}/**/*.so*").select do |f|
        next unless File.file?(f)

        # Use the MIME type reported by `file` to verify it's actually a
        # shared object. The MIME type is a fixed, machine-readable string,
        # unlike the human-readable description which varies between versions.
        output = Gitlab::Util.shellout_stdout("file -b --mime-type #{Shellwords.escape(f)}", timeout: SHELLOUT_TIMEOUT)
        output == SHARED_LIBRARY_MIME_TYPE
      rescue Gitlab::Util::ShellOutExecutionError
        false
      end
    end

    def find_binaries
      bin_dir = File.join(@install_dir, 'embedded', 'bin')
      return [] unless File.directory?(bin_dir)

      Dir.glob("#{bin_dir}/*").select do |f|
        next unless File.file?(f)

        # Use the MIME type reported by `file` to verify it's actually an ELF
        # executable (including position-independent executables).
        output = Gitlab::Util.shellout_stdout("file -b --mime-type #{Shellwords.escape(f)}", timeout: SHELLOUT_TIMEOUT)
        EXECUTABLE_MIME_TYPES.include?(output)
      rescue Gitlab::Util::ShellOutExecutionError
        false
      end
    end

    def check_file(file)
      output = Gitlab::Util.shellout_stdout("objdump -t #{Shellwords.escape(file)}", timeout: SHELLOUT_TIMEOUT)
      output = reject_ignored_symbols(output, file)

      glibc_versions = extract_glibc_versions(output)

      if glibc_versions.any?
        update_max_version(glibc_versions)
        track_file_version(file, glibc_versions.last)
        @symbols_by_file[file] = extract_glibc_symbols(output)
      end
    rescue Gitlab::Util::ShellOutExecutionError => e
      @issues << "Error checking #{file}: objdump failed (#{e.message})"
    end

    def reject_ignored_symbols(objdump_output, file)
      return objdump_output if objdump_output.nil?

      symbols = ignored_symbols_for(file)
      return objdump_output if symbols.empty?

      objdump_output.each_line.reject do |line|
        symbols.any? { |symbol| line.include?("#{symbol}@GLIBC_") }
      end.join
    end

    def ignored_symbols_for(file)
      IGNORED_SYMBOLS_BY_PATH.each_with_object([]) do |(pattern, symbols), result|
        result.concat(symbols) if pattern.match?(file)
      end
    end

    def extract_glibc_versions(objdump_output)
      versions = Set.new

      objdump_output.each_line do |line|
        # Match lines like: 0000000000000000  *UND*  FUNC    GLOBAL DEFAULT  UND GLIBC_2.17
        data = /GLIBC_(\d+(?:\.\d+)+)/.match(line)
        versions << data[1] if data
      end

      versions.to_a.sort_by { |v| Gem::Version.new(v) }
    end

    def extract_glibc_symbols(objdump_output)
      symbols_by_version = Hash.new { |h, k| h[k] = [] }

      objdump_output.each_line do |line|
        # Match symbols like: epoll_pwait2@GLIBC_2.35
        match = /(\S+@GLIBC_(\d+(?:\.\d+)+))/.match(line)
        symbols_by_version[match[2]] << match[1] if match
      end

      symbols_by_version
    end

    def track_file_version(file, version)
      @files_by_version[version] ||= []
      @files_by_version[version] << file
    end

    def update_max_version(versions)
      return if versions.empty?

      latest = versions.last
      @max_required_version = latest if @max_required_version.nil? || Gem::Version.new(latest) > Gem::Version.new(@max_required_version)
    end

    def report_results
      log_info "\n#{'=' * 60}"
      log_info "GLIBC Version Summary"
      log_info "=" * 60
      log_info "System GLIBC version: #{@system_version}"
      log_info "Maximum required GLIBC version: #{@max_required_version || 'none found'}"

      if @max_required_version && @system_version != 'unknown'
        if Gem::Version.new(@max_required_version) > Gem::Version.new(@system_version)
          @issues << "Maximum required GLIBC version (#{@max_required_version}) exceeds system version (#{@system_version})"
          log_files_exceeding_system_version
        else
          log_info "✓ System GLIBC version is compatible"
        end
      end

      if @issues.any?
        log_error "\nIssues found:"
        @issues.each { |issue| log_error "  - #{issue}" }
        raise "GLIBC check failed with #{@issues.length} error(s)"
      else
        log_info "\nGLIBC check completed successfully"
      end
    end

    def log_files_exceeding_system_version
      system_ver = Gem::Version.new(@system_version)
      exceeding_files = []

      @files_by_version.each do |version, files|
        exceeding_files.concat(files) if Gem::Version.new(version) > system_ver
      end

      return unless exceeding_files.any?

      log_error "\nFiles exceeding system GLIBC version (#{@system_version}):"
      exceeding_files.sort.each do |file|
        log_error "  - #{file}"
        symbols = @symbols_by_file[file]
        next unless symbols

        symbols.each do |version, syms|
          next unless Gem::Version.new(version) > system_ver

          syms.each { |sym| log_error "      #{sym}" }
        end
      end
    end
  end
end
