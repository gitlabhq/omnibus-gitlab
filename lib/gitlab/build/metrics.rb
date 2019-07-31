require_relative "info.rb"
require "google_drive"
require "open3"

module Build
  class Metrics
    class << self
      def configure_gitlab_repo
        # Install recommended softwares for installing GitLab EE
        system(*%w[apt-get update])
        system(*%w[apt-get install -y curl openssh-server ca-certificates])
        Open3.pipeline(
          %w[curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh],
          %w[bash]
        )
      end

      def install_package(version)
        # Deleting RUBY and BUNDLE related env variables so rake tasks ran
        # during reconfigure won't use gems from builder image.
        ENV.delete_if { |name, _v| name =~ /^(RUBY|BUNDLE)/ }

        system(
          { 'EXTERNAL_URL' => 'http://gitlab.example.com' },
          *%W[apt-get -y install gitlab-ee=#{version}]
        )

        spawn('/opt/gitlab/embedded/bin/runsvdir-start')
        system(*%w[gitlab-ctl reconfigure])
      end

      def upgrade_package
        # For the current version, use the package from S3 bucket and not depend
        # upon the packagecloud repository.
        system(*%W[curl -q -o gitlab.deb #{Build::Info.package_download_url}])
        system(*%w[dpkg -i gitlab.deb])
      end

      def should_upgrade?
        # We need not update if the tag is either from an older version series or a
        # patch release or a CE version.
        status = true
        if !Build::Check.is_ee?
          puts "Not an EE package. Not upgrading."
          status = false
        elsif Build::Check.is_patch_release?
          puts "Not a major/minor release. Not upgrading."
          status = false
        elsif !Build::Check.is_latest_stable_tag?
          # Checking if latest stable release.
          # TODO: Refactor the method name to be more explanatory
          # https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3274
          puts "Not a latest stable release. Not upgrading."
          status = false
        end
        status
      end

      def get_latest_log(final_location)
        # Getting last block from log to a separate file.
        log_location = "/var/log/apt/term.log"

        # 1. tac will reverse the log and give it to sed
        # 2. sed will get the string till the first "Log started" string
        #    (which corresponds to the last log block).
        # 3. Next tac will again reverse it, hence producing log in proper order
        Open3.pipeline(
          %W[tac #{log_location}],
          %w[sed /^Log\ started/q],
          %w[tac],
          out: final_location
        )
      end

      def calculate_duration
        latest_log_location = "/tmp/upgrade.log"
        get_latest_log(latest_log_location)
        duration = nil

        # Logs from apt follow the format `Log (started|ended): <date>  <time>`
        File.open(latest_log_location) do |f|
          start_string = f.grep(/Log started/)[0].strip.gsub("Log started: ", "")
          f.rewind
          end_string = f.grep(/Log ended/)[0].strip.gsub("Log ended: ", "")

          start_time = DateTime.strptime(start_string, "%Y-%m-%d  %H:%M:%S")
          end_time = DateTime.strptime(end_string, "%Y-%m-%d  %H:%M:%S")
          duration = ((end_time - start_time) * 24 * 60 * 60).to_i
        end

        duration
      end

      def append_to_sheet(version, duration)
        # Append duration to Google Sheets where a chart will be generated
        service_account_file = File.expand_path('../../../service_account.json', __dir__)
        session = GoogleDrive::Session.from_service_account_key(service_account_file)
        spreadsheet = session.spreadsheet_by_title("GitLab EE Upgrade Metrics")
        worksheet = spreadsheet.worksheets.first
        worksheet.insert_rows(worksheet.num_rows + 1, [[version, duration]])
        worksheet.save
      end
    end
  end
end
