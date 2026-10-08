require_relative '../ohai_helper'

module Build
  # The SELinux policy modules shipped in /opt/gitlab/embedded/selinux.
  class SELinuxPolicy
    # checkmodule writes the newest module format the build host's libsepol
    # supports unless told otherwise. Builder images track the latest minor
    # release of each OS, so an unpinned module stops loading on hosts still
    # running an older minor of the same major (format 24 vs. EL 10.1's 4-23).
    # See https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/10132
    #
    # 19 (MOD_POLICYDB_VERSION_INFINIBAND) is the newest format EL 8's
    # libsepol 2.9 can read or write, and every newer libsepol reads it,
    # including upstream's raised minimum of 18. Our .te sources use nothing
    # newer. The MOD_POLICYDB_VERSION_* constants are defined in
    # https://github.com/SELinuxProject/selinux/blob/3.10/libsepol/include/sepol/policydb/policydb.h#L783-L808
    MODULE_POLICY_VERSION = 19

    # Layout of a policy package (.pp) header, all fields little-endian
    # uint32: package magic, package version, section count, then one offset
    # per section. Section 0 is the module: magic, the length of the module
    # string that follows, the string itself, policy type, policy version.
    #
    # SEPOL_MODULE_PACKAGE_MAGIC:
    # https://github.com/SELinuxProject/selinux/blob/3.10/libsepol/include/sepol/policydb/module.h#L31
    PACKAGE_MAGIC = 0xf97cff8f
    # SELINUX_MOD_MAGIC, aliased as POLICYDB_MOD_MAGIC in policydb.h#L842:
    # https://github.com/SELinuxProject/selinux/blob/3.10/libsepol/include/sepol/policydb/flask_types.h#L49
    MODULE_MAGIC = 0xf97cff8d

    class << self
      # checkpolicy 2.9 (EL 8) has no -c option, and the newest format it
      # writes is already MODULE_POLICY_VERSION.
      def checkmodule_flags
        return '' if OhaiHelper.os_platform == 'el' && OhaiHelper.os_platform_version.to_i < 9

        "-c #{MODULE_POLICY_VERSION}"
      end

      # Returns the module format version of the policy package at `path`.
      def module_policy_version(path)
        data = File.binread(path)

        raise "#{path} is not an SELinux policy package" unless uint32(data, 0, path) == PACKAGE_MAGIC

        offset = uint32(data, 12, path)
        raise "#{path} does not start with a policy module" unless uint32(data, offset, path) == MODULE_MAGIC

        name_length = uint32(data, offset + 4, path)
        uint32(data, offset + 8 + name_length + 4, path)
      end

      def verify!(path)
        version = module_policy_version(path)
        return if version == MODULE_POLICY_VERSION

        raise "#{path} uses SELinux module format #{version}, expected #{MODULE_POLICY_VERSION}. " \
              "Hosts with an older libsepol cannot load it; check the checkmodule flags in " \
              "config/software/gitlab-selinux.rb."
      end

      private

      def uint32(data, offset, path)
        value = data.byteslice(offset, 4)&.unpack1('V')
        raise "#{path} is truncated at byte #{offset}" if value.nil?

        value
      end
    end
  end
end
