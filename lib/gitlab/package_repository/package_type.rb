class PackageRepository
  class PulpRepository < Base
    # Base class for package types
    class PackageType
      attr_reader :file_extension

      def initialize(file_extension)
        @file_extension = file_extension
      end

      # Factory method to create the appropriate package type
      # @param package_name [String] The package file name
      # @return [PackageType] The appropriate package type instance
      def self.from_filename(package_name)
        if package_name.end_with?('.deb')
          DebPackage.new
        elsif package_name.end_with?('.rpm')
          RpmPackage.new
        else
          raise "Unknown package type for file: #{package_name}"
        end
      end

      # Returns the package type name
      # @return [String] The package type ('deb' or 'rpm')
      def type_name
        raise NotImplementedError, "Subclasses must implement type_name"
      end

      # Extracts distribution path from platform directory name
      # @param platform_dir [String] The platform directory name (e.g., "ubuntu-focal_aarch64", "el-8_aarch64")
      # @return [String] The distribution path (e.g., "ubuntu/focal", "el/8/aarch64")
      def extract_distribution(platform_dir)
        raise NotImplementedError, "Subclasses must implement extract_distribution"
      end

      # Builds the upload command for this package type
      # @param file_path [String] Path to the package file
      # @param repository_name [String] Repository name
      # @param distribution_version [String] Distribution version (may not be used by all package types)
      # @param component [String] Component name (may not be used by all package types)
      # @param chunk_size [Integer] Chunk size for upload
      # @return [Array] The upload command as an array
      def build_upload_command(file_path:, repository_name:, distribution_version:, component:, chunk_size:)
        raise NotImplementedError, "Subclasses must implement build_upload_command"
      end
    end

    # Debian package type
    class DebPackage < PackageType
      def initialize
        super('.deb')
      end

      def type_name
        'deb'
      end

      # Extracts distribution path from platform directory name for Debian packages
      # Examples:
      #   "ubuntu-focal_aarch64" -> "ubuntu/focal"
      #   "ubuntu-focal_fips" -> "ubuntu/focal"
      #   "ubuntu-focal" -> "ubuntu/focal"
      # @param platform_dir [String] The platform directory name
      # @return [String] The distribution path
      def extract_distribution(platform_dir)
        # Remove architecture or fips suffix (anything after _)
        base_platform = platform_dir.gsub(/_.*/, '')

        # Split distro-version and convert to path
        # "ubuntu-focal" -> "ubuntu/focal"
        base_platform.sub('-', '/')
      end

      # Builds the upload command for Debian packages
      def build_upload_command(file_path:, repository_name:, distribution_version:, component:, chunk_size:)
        [
          "pulp", type_name, "content", "upload",
          "--file", file_path,
          "--repository", repository_name,
          "--distribution", distribution_version,
          "--component", component,
          "--chunk-size", chunk_size.to_s
        ]
      end
    end

    # RPM package type
    class RpmPackage < PackageType
      def initialize
        super('.rpm')
      end

      def type_name
        'rpm'
      end

      # Extracts distribution path from platform directory name for RPM packages
      # Examples:
      #   "el-8_aarch64" -> "el/8/aarch64"
      #   "el-8" -> "el/8/x86_64"
      #   "amazon-2023_aarch64" -> "amazon/2023/aarch64"
      #   "opensuse-15.6" -> "opensuse/15.6/x86_64"
      #   "opensuse-15.6_fips" -> "opensuse/15.6/x86_64"
      # @param platform_dir [String] The platform directory name
      # @return [String] The distribution path
      def extract_distribution(platform_dir)
        # Remove fips suffix if present
        clean_platform = platform_dir.gsub(/_fips$/, '')

        # Extract architecture if present, default to x86_64
        if clean_platform =~ /^(.+)_(aarch64|x86_64)$/
          base = Regexp.last_match(1)
          arch = Regexp.last_match(2)
        else
          base = clean_platform
          arch = 'x86_64'
        end

        # Split distro-version and convert to path with architecture
        # "el-8" -> "el/8/x86_64"
        # "amazon-2023" -> "amazon/2023/x86_64"
        parts = base.split('-', 2)
        "#{parts[0]}/#{parts[1]}/#{arch}"
      end

      # Builds the upload command for RPM packages
      # Does not include --distribution and --component flags, as compared to the deb upload command
      def build_upload_command(file_path:, repository_name:, distribution_version:, component:, chunk_size:)
        [
          "pulp", type_name, "content", "-t", "package", "upload",
          "--file", file_path,
          "--repository", repository_name,
          "--chunk-size", chunk_size.to_s
        ]
      end
    end
  end
end
