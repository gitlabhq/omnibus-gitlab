class LicenseAnalyzer
  @license_acceptable = Regexp.union([/MIT/i, /LGPL/i, /Apache/i, /Ruby/i, /BSD/i,
                                      /ISO/i, /ISC/i, /Public[- ]Domain/i,
                                      /Unlicense/i, /Artistic/i, /MPL/i, /AFL/i,
                                      /CC-BY-[0-9]*/, /^project_license$/, /OpenSSL/i,
                                      /ZLib/i, /jemalloc/i, /Python/i, /PostgreSQL/i,
                                      /Info-Zip/i])
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
    'mysql-client',       # GPL Mere Aggregate Exception - https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation
    'repmgr',             # GPL Mere Aggregate Exception - https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation
    'blob',               # MIT Licensed - https://github.com/webmodules/blob/blob/master/LICENSE
    'callsite',           # MIT Licensed - https://github.com/tj/callsite/blob/master/LICENSE
    'component-bind',     # MIT Licensed - https://github.com/component/bind/blob/master/LICENSE
    'component-inherit',  # MIT Licensed - https://github.com/component/inherit/blob/master/LICENSE
    'domelementtype',     # BSD-2-Clause Licensed - https://github.com/fb55/domelementtype/blob/master/LICENSE
    'domhandler',         # BSD-2-Clause Licensed - https://github.com/fb55/domhandler/blob/master/LICENSE
    'domutils',           # BSD-2-Clause Licensed - https://github.com/fb55/domutils/blob/master/LICENSE
    'fsevents',           # MIT Licensed - https://github.com/strongloop/fsevents/blob/master/LICENSE
    'indexof',            # MIT Licensed - https://github.com/component/indexof/blob/master/LICENSE
    'map-stream',         # MIT Licensed - https://github.com/dominictarr/map-stream/blob/master/LICENCE
    'object-component',   # MIT Licensed - https://github.com/component/object/blob/master/LICENSE
    'select2',            # MIT Licensed - https://github.com/select2/select2/blob/master/LICENSE.md
  ]
  # readline is GPL licensed and its use was not mere aggregation. Hence it is
  # blacklisted.
  # Details: https://gitlab.com/gitlab-org/omnibus-gitlab/issues/1945#note_29286329
  @software_unacceptable = ['readline']

  def self.software_check(dependency)
    if @software_unacceptable.include?(dependency)
      ['unacceptable', 'Blacklisted software']
    elsif @software_acceptable.include?(dependency)
      ['acceptable', 'Whitelisted software']
    end
  end

  def self.license_check(license)
    if license.match(@license_acceptable)
      ['acceptable', 'Acceptable license']
    elsif license.match(@license_unacceptable)
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

  def self.analyze(json_data)
    violations = []
    json_data.each do |dependency, attributes|
      license = attributes['license'].strip.delete('"').delete("'")
      version = attributes['version']
      status, reason = acceptable?(dependency, license.strip)

      case status
      when 'acceptable'
        puts "Acceptable   : #{dependency} - #{version} uses #{license} - #{reason}"
      when 'unacceptable'
        violations << "#{dependency} - #{version} - #{license} - #{reason}"
        if reason == 'Blacklisted software'
          puts "Unacceptable ! #{dependency} - #{version} uses #{license} - #{reason}"
        elsif reason == 'Unknown license'
          puts "Unknown      ? #{dependency} - #{version} uses #{license} - #{reason}"
        end
      end
    end

    violations
  end
end
