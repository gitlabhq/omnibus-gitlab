require_relative 'base'
require_relative 'package_type'
require 'pathname'

class PackageRepository
  # Pulp repository implementation for uploading packages to Pulp servers.
  # Uses the pulp CLI to upload Debian and RPM packages.
  class PulpRepository < Base
    # Default chunk size for uploading packages (10 MB)
    DEFAULT_CHUNK_SIZE = 10_000_000

    # Default Pulp server URL
    DEFAULT_PULP_URL = 'https://pulp.gitlab.com'.freeze

    # Uploads packages to Pulp repository
    # @param repository [String, nil] Optional repository override
    # @param dry_run [Boolean] Whether to perform a dry run without actual upload
    def upload(repository = nil, dry_run = false)
      upload_list = package_list(repository)
      raise "No packages found for upload. Are artifacts available?" if upload_list.empty?

      validate(dry_run)

      # Authenticate with Pulp server
      authenticate(dry_run)

      upload_list.each do |pkg_info|
        file_path = pkg_info[:file_path]
        repository_name = pkg_info[:repository]
        distribution = pkg_info[:distribution]
        component = pkg_info[:component]
        package_type = pkg_info[:package_type]

        # Build upload command using package type
        upload_cmd = package_type.build_upload_command(
          file_path: file_path,
          repository_name: repository_name,
          distribution: distribution,
          component: component,
          chunk_size: chunk_size
        )

        next if dry_run

        Retriable.with_context(:package_publish, on: PackageUploadError) do
          puts "Uploading...\n"
          puts "Running the command: #{upload_cmd.join(' ')}"

          begin
            Gitlab::Util.shellout_stdout(upload_cmd)
          rescue Gitlab::Util::ShellOutExecutionError => e
            warn 'Upload to Pulp server failed!.'
            warn "The command returned the output: #{e.stdout}#{e.stderr}"
            raise PackageUploadError, "Upload to Pulp server failed!."
          end

          puts "Package #{file_path} uploaded successfully.\n"
        end
      end
    end

    private

    # Returns the chunk size for uploading packages
    # @return [Integer] The chunk size from PULP_CHUNK_SIZE environment variable or default
    def chunk_size
      size = Gitlab::Util.get_env('PULP_CHUNK_SIZE')
      return DEFAULT_CHUNK_SIZE if size.nil? || size&.empty?

      begin
        parsed_size = Integer(size)
        parsed_size.positive? ? parsed_size : DEFAULT_CHUNK_SIZE
      rescue ArgumentError
        DEFAULT_CHUNK_SIZE
      end
    end

    # Returns the Pulp server base URL
    # @return [String] The Pulp server URL from PULP_URL environment variable or default
    def pulp_url
      Gitlab::Util.get_env('PULP_URL') || DEFAULT_PULP_URL
    end

    # Authenticates with the Pulp server using pulp config create
    # @param dry_run [Boolean] Whether to perform a dry run
    def authenticate(dry_run)
      return if dry_run

      user = Gitlab::Util.get_env('PULP_USER')
      password = Gitlab::Util.get_env('PULP_PASSWORD')

      raise PackageUploadError, "PULP_USER environment variable is required" if user.nil? || user.empty?
      raise PackageUploadError, "PULP_PASSWORD environment variable is required" if password.nil? || password.empty?

      config_cmd = [
        "pulp", "config", "create",
        "--base-url", pulp_url,
        "--api-root", "/pulp/",
        "--verify-ssl",
        "--format", "json",
        "--force",
        "--username", user,
        "--password", password,
        "--timeout", "0", # Let the CI job handles timeout
        "--overwrite"
      ]

      puts "Creating Pulp configuration...\n"

      begin
        Gitlab::Util.shellout_stdout(config_cmd)
      rescue Gitlab::Util::ShellOutExecutionError => e
        warn 'Pulp configuration creation failed!'
        warn "The command returned the output: #{e.stdout}#{e.stderr}"
        raise PackageUploadError, "Pulp configuration creation failed!"
      end

      puts "Successfully created Pulp configuration.\n"
    end

    # Generates the list of packages to upload to Pulp
    # @param repository [String, nil] Optional repository override
    # @return [Array<Hash>] Array of package information hashes
    def package_list(repository)
      list = []

      Build::Info::Package.file_list.each do |path|
        platform_path = validate_package_path(path)

        platform_dir = platform_path[1] # "ubuntu-focal_aarch64" or "el-8_aarch64"
        package_name = platform_path[2] # "gitlab-ce.deb" or "gitlab-ce.rpm"
        package_path = Pathname(platform_path[0]).join(platform_dir, package_name).to_s
        target_repository = repository || target # staging override or the rest, eg. "unstable"

        package_type = PackageType.from_filename(package_name)
        os_dist = package_type.extract_distribution(platform_dir)

        repository_name = "gitlab-#{target_repository}-#{os_dist.tr('/', '-')}"
        component = 'main'

        list << {
          file_path: package_path,
          repository: repository_name,
          distribution: repository_name, # repository and distribution are always the same
          component: component,
          package_type: package_type
        }

        # Add additional platform entries (EL to OL, OpenSUSE to SLES)
        add_additional_platforms(list, platform_dir,
                                 package_path: package_path,
                                 target_repository: target_repository,
                                 component: component,
                                 package_type: package_type)
      end

      list
    end

    # Adds additional platform entries for cross-compatible distributions
    # @param list [Array] The list to append additional entries to
    # @param platform_dir [String] The platform directory name (e.g., "el-8_aarch64", "opensuse-15.6")
    # @param args [Hash] Additional arguments (package_path, target_repository, component, package_type)
    # @return [void]
    def add_additional_platforms(list, platform_dir, **args)
      add_oracle_linux_platform(list, platform_dir, **args)
      add_sles_platform(list, platform_dir, **args)
    end

    # Adds Oracle Linux platform entry for Enterprise Linux packages
    # @param list [Array] The list to append additional entries to
    # @param platform_dir [String] The platform directory name (e.g., "el-8_aarch64")
    # @param args [Hash] Additional arguments
    # @return [void]
    def add_oracle_linux_platform(list, platform_dir, **args)
      return unless platform_dir.start_with?("el-")

      # Transform the OS distribution: "el/8/aarch64" -> "ol/8/aarch64"
      original_os_dist = args[:package_type].extract_distribution(platform_dir)
      additional_os_dist = original_os_dist.sub('el/', 'ol/')
      additional_repository_name = "gitlab-#{args[:target_repository]}-#{additional_os_dist.tr('/', '-')}"

      list << {
        file_path: args[:package_path],
        repository: additional_repository_name,
        distribution: additional_repository_name, # repository and distribution are always the same
        component: args[:component],
        package_type: args[:package_type]
      }
    end

    # Adds SLES platform entry for OpenSUSE packages
    # @param list [Array] The list to append additional entries to
    # @param platform_dir [String] The platform directory name (e.g., "opensuse-15.6")
    # @param args [Hash] Additional arguments
    # @return [void]
    def add_sles_platform(list, platform_dir, **args)
      return unless platform_dir.start_with?("opensuse-")

      # Transform the OS distribution: "opensuse/15.6/x86_64" -> "sles/15.6/x86_64"
      original_os_dist = args[:package_type].extract_distribution(platform_dir)
      additional_os_dist = original_os_dist.sub('opensuse/', 'sles/')
      additional_repository_name = "gitlab-#{args[:target_repository]}-#{additional_os_dist.tr('/', '-')}"

      list << {
        file_path: args[:package_path],
        repository: additional_repository_name,
        distribution: additional_repository_name, # repository and distribution are always the same
        component: args[:component],
        package_type: args[:package_type]
      }
    end
  end
end
