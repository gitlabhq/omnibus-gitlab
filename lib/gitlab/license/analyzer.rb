require_relative '../build/info/package'

module License
  class Analyzer
    @license_acceptable = Regexp.union([/MIT/i, /LGPL/i, /Apache/i, /Ruby/i, /BSD/i,
                                        /ISO/i, /ISC/i, /Public[- ]Domain/i,
                                        /Unlicense/i, /Artistic/i, /MPL/i, /AFL/i,
                                        /CC-BY-[0-9]*/, /^project_license$/, /OpenSSL/i,
                                        /ZLib/i, /jemalloc/i, /Python/i, /PostgreSQL/i,
                                        /Info-Zip/i, /Libpng/i, /Mozilla Public/i, /libtiff/i, /WTFPL/, /CC0/,
                                        /OFL-1.1/, /SIL OPEN FONT LICENSE/i])
    # TODO: Re-confirm that licenses Python, Info-Zip, OpenSSL and CC-BY are
    # OK to be shipped. https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2448

    @license_unacceptable = Regexp.union([/GPL/i, /AGPL/i])
    @software_acceptable = [
      'git',                # GPL Mere Aggregate Exception - https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation
      'config_guess',       # GPL Mere Aggregate Exception - https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation
      'pkg-config-lite',    # GPL Mere Aggregate Exception - https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation
      'libtool',            # GPL Mere Aggregate Exception - https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation
      'logrotate',          # GPL Mere Aggregate Exception - https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation
      'rsync',              # GPL Mere Aggregate Exception - https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation
      'blob',               # MIT Licensed - https://github.com/webmodules/blob/blob/master/LICENSE
      'callsite',           # MIT Licensed - https://github.com/tj/callsite/blob/master/LICENSE
      'component-bind',     # MIT Licensed - https://github.com/component/bind/blob/master/LICENSE
      'component-inherit',  # MIT Licensed - https://github.com/component/inherit/blob/master/LICENSE
      'domelementtype',     # BSD-2-Clause Licensed - https://github.com/fb55/domelementtype/blob/master/LICENSE
      'domhandler',         # BSD-2-Clause Licensed - https://github.com/fb55/domhandler/blob/master/LICENSE
      'domutils',           # BSD-2-Clause Licensed - https://github.com/fb55/domutils/blob/master/LICENSE
      "eventmachine-tail",  # BSD-3-Clause Licensed - https://code.google.com/archive/p/semicomplete
      'inspec-core',        # Apache Licensed (gem published from Cinc): https://github.com/inspec/inspec/blob/v6.6.0/LICENSE
      'net-protocol',       # BSD-2-Clause Licensed - https://github.com/ruby/net-protocol/blob/master/LICENSE.txt
      'fsevents',           # MIT Licensed - https://github.com/strongloop/fsevents/blob/master/LICENSE
      'indexof',            # MIT Licensed - https://github.com/component/indexof/blob/master/LICENSE
      'map-stream',         # MIT Licensed - https://github.com/dominictarr/map-stream/blob/master/LICENCE
      'object-component',   # MIT Licensed - https://github.com/component/object/blob/master/LICENSE
      'pdf-core',           # Custom License - https://gitlab.com/gitlab-com/legal-and-compliance/-/issues/2565
      'prawn',              # Custom License - https://gitlab.com/gitlab-com/legal-and-compliance/-/issues/2565
      'exiftool',           # License similar to Perl, which is under either GPL v1 or Artistic license - https://www.sno.phy.queensu.ca/~phil/exiftool/#license
      'github.com/cloudflare/tableflip', # BSD-3-Clause Licensed - https://github.com/cloudflare/tableflip/blob/master/LICENSE
      'gitlab.com/gitlab-org/golang-archive-zip', # BSD-3-Clause Licensed - https://gitlab.com/gitlab-org/golang-archive-zip/-/blob/c8e752e2d582090de40338553ef00ef08b89c905/LICENSE
      'spam-classifier',    # GitLab project and we can distribute the obfuscated binaries
      'syslog_protocol',    # MIT Licensed - https://github.com/eric/syslog_protocol?tab=readme-ov-file#todo
      'ttfunk',             # Custom License - https://gitlab.com/gitlab-com/legal-and-compliance/-/issues/2565
      'elkjs',              # EPL 2.0 - https://github.com/kieler/elkjs/blob/master/LICENSE.md
      'consul',             # BSL - consul - https://gitlab.com/gitlab-com/Product/-/issues/12681#note_1620313057
      './troubleshoot',     # BSL - consul/troubleshoot module
      './envoyextensions',  # BSL - consul/envoyextensions module
    ]
    # readline is GPL licensed and its use was not mere aggregation. Hence it is
    # denylisted.
    # Details: https://gitlab.com/gitlab-org/omnibus-gitlab/issues/1945#note_29286329
    @software_unacceptable = ['readline']

    def self.software_check(dependency)
      if @software_unacceptable.include?(dependency)
        ['unacceptable', 'Denylisted software']
      elsif @software_acceptable.include?(dependency)
        ['acceptable', 'Allowlisted software']
      end
    end

    def self.license_check(license)
      if @license_acceptable.match?(license)
        ['acceptable', 'Acceptable license']
      elsif @license_unacceptable.match?(license)
        ['unacceptable', 'Unacceptable license']
      end
    end

    def self.acceptable?(dependency, license)
      # This method returns two values. First one is whether the software is
      # acceptable or not. Second one is the reason for that decision. This
      # information is relayed to the user for better transparency.

      software_check_status = software_check(dependency)
      return software_check_status if software_check_status # status is nil if software is unlisted

      license_check_status = license_check(license)
      return license_check_status if license_check_status # status is nil if license is unlisted

      ['unacceptable', 'Unknown license']
    end

    def self.status_string(dependency, version, license, status, reason, level)
      # level is used to properly align the output. First level dependencies
      # (level-0) have no indentation. Their dependencies, the level-1 ones,
      # are indented.
      string = ""
      case status
      when 'acceptable'
        if reason == 'Acceptable license'
          string = "\t" * level + "✓ #{dependency} - #{version} uses #{license} - #{reason}\n"
        elsif reason == 'Allowlisted software'
          string = "\t" * level + "# #{dependency} - #{version} uses #{license} - #{reason}\n"
        end
      when 'unacceptable'
        string = if reason == 'Unknown license'
                   "\t" * level + "! #{dependency} - #{version} uses #{license} - #{reason}\n"
                 else
                   "\t" * level + "⨉ #{dependency} - #{version} uses #{license} - #{reason}\n"
                 end
      end
      string
    end

    def self.analyze(json_data)
      violations = []
      output_json = {}

      # We are currently considering dependencies in a two-level view only. This
      # means some information will be repeated as there are softwares that are
      # dependencies of multiple components and they get listed again and again.

      # Handling level-0 dependencies
      json_data.each do |library|
        level = 0
        name = library['name']
        license = library['license'].strip.delete('"').delete("'")
        version = library['version']
        status, reason = acceptable?(name, license.strip)
        message = status_string(name, version, license, status, reason, level)
        puts message
        violations << "#{name} - #{version} - #{license} - #{reason}" if status == 'unacceptable'
        output_json[name] = {
          license: license,
          version: version,
          status: status,
          reason: reason,
          dependencies: {}
        }

        # Handling level-1 dependencies
        library['dependencies'].each do |dependency|
          level = 1
          name = dependency['name']
          license = dependency['license'].strip.delete('"').delete("'")
          version = dependency['version']
          status, reason = acceptable?(name, license.strip)
          message = status_string(name, version, license, status, reason, level)
          puts message
          violations << "#{name} - #{version} - #{license} - #{reason}" if status == 'unacceptable'
          output_json[library['name']][:dependencies][name] = {
            license: license,
            version: version,
            status: status,
            reason: reason,
          }
        end
      end

      File.open("pkg/#{Build::Info::Package.name}_#{Build::Info::Package.release_version}.license-status.json", "w") do |f|
        f.write(JSON.pretty_generate(output_json))
      end

      violations.uniq
    end
  end
end
