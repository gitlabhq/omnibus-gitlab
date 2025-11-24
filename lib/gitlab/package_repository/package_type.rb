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
        raise "Unknown package type for file: #{package_name}" unless package_name.end_with?('.deb')

        DebPackage.new
      end

      # Returns the package type name
      # @return [String] The package type ('deb' or 'rpm')
      def type_name
        raise NotImplementedError, "Subclasses must implement type_name"
      end

      # Transforms the platform name according to package type rules
      # @param platform_name [String] The raw platform name (e.g., "ubuntu-xenial_aarch64")
      # @return [String] The transformed platform name
      def transform_platform(platform_name)
        raise NotImplementedError, "Subclasses must implement transform_platform"
      end

      # Builds the upload command for this package type
      # @param file_path [String] Path to the package file
      # @param repository_name [String] Repository name
      # @param distribution [String] Distribution name (may not be used by all package types)
      # @param component [String] Component name (may not be used by all package types)
      # @param chunk_size [Integer] Chunk size for upload
      # @return [Array] The upload command as an array
      def build_upload_command(file_path:, repository_name:, distribution:, component:, chunk_size:)
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

      # For deb packages, strip architecture suffix from platform name
      def transform_platform(platform_name)
        platform_name.gsub(/_.*/, '') # "ubuntu-xenial_aarch64" -> "ubuntu-xenial"
      end

      # Builds the upload command for Debian packages
      def build_upload_command(file_path:, repository_name:, distribution:, component:, chunk_size:)
        [
          "pulp", type_name, "content", "upload",
          "--file", file_path,
          "--repository", repository_name,
          "--distribution", distribution,
          "--component", component,
          "--chunk-size", chunk_size.to_s
        ]
      end
    end
  end
end
