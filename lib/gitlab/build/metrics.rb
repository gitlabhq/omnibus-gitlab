require_relative "info.rb"

module Build
  class Metrics
    class << self
      def install_package
        system("sudo apt-get update && sudo apt-get -y install gitlab-ee=#{Info.release_version}")
      end

      def should_upgrade?
        # We need not update if the tag is either from an older version series or a
        # patch release or a CE version.
        status = true
        if !Build::Check.is_ee?
          puts "Not an EE package. Not upgrading."
          status = false
        elsif !Build::Check.is_an_upgrade?
          puts "Not the latest package. Not upgrading."
          status = false
        elsif Build::Check.is_patch_release?
          puts "Not a major/minor release. Not upgrading."
          status = false
        end
        status
      end
    end
  end
end
