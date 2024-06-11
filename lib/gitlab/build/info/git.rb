require_relative '../../util'
require_relative '../check'
require_relative 'ci'

module Build
  class Info
    class Git
      class << self
        def branch_name
          # If on CI, branch name from `CI_COMMIT_BRANCH` wins
          result = Build::Info::CI.branch_name

          return result if result

          # If not on CI, attempt to detect branch name
          head_reference = Gitlab::Util.shellout_stdout('git rev-parse --abbrev-ref HEAD')

          # On tags, the shell command will return `HEAD`. If that is not the
          # case, we are on a branch and can return the output we received.
          return head_reference unless head_reference == "HEAD"
        end

        def tag_name
          Build::Info::CI.tag_name || Gitlab::Util.shellout_stdout('git describe --tags --exact-match')
        rescue Gitlab::Util::ShellOutExecutionError => e
          return nil if /fatal: no tag exactly matches/.match?(e.stderr)

          raise "#{e.message}\nSTDOUT: #{e.stdout}\nSTDERR: #{e.stderr}"
        end

        def commit_sha
          commit_sha_raw = Gitlab::Util.get_env('CI_COMMIT_SHA') || Gitlab::Util.shellout_stdout('git rev-parse HEAD')

          commit_sha_raw[0, 8]
        end

        # TODO, merge latest_tag with latest_stable_tag
        # TODO, add tests, needs a repo clone
        def latest_tag
          unless (fact_from_file = Gitlab::Util.fetch_fact_from_file(__method__)).nil?
            return fact_from_file
          end

          tags = sorted_tags_for_edition

          return if tags.empty?

          branch_for_version = Build::Info::CI.mr_target_branch_name || branch_name

          version = branch_for_version.delete_suffix('-stable').tr('-', '.') if Build::Check.on_stable_branch? || Build::Check.mr_targetting_stable_branch?
          output = tags.find { |t| t.start_with?("#{version}.") } if version

          # If no tags corresponding to the stable branch version was found, we
          # fall back to the latest available tag
          output || tags.first
        end

        def latest_stable_tag(level: 1)
          unless (fact_from_file = Gitlab::Util.fetch_fact_from_file(__method__)).nil?
            return fact_from_file
          end

          # Exclude RC tags so that we only have stable tags.
          stable_tags = sorted_tags_for_edition.reject { |t| t.include?('rc') }

          return if stable_tags.empty?

          branch_for_version = Build::Info::CI.mr_target_branch_name || branch_name

          version = branch_for_version.delete_suffix('-stable').tr('-', '.') if Build::Check.on_stable_branch? || Build::Check.mr_targetting_stable_branch?

          results = stable_tags.select { |t| t.start_with?("#{version}.") } if version

          # If no tags corresponding to the stable branch version was found, we
          # fall back to the latest available stable tag
          output = if results.nil? || results.empty?
                     stable_tags
                   else
                     results
                   end

          # Level decides tag at which position you want. Level one gives you
          # latest stable tag, two gives you the one just before it and so on.
          # Since arrays start from 0, we subtract 1 from the specified level to
          # get the index. If the specified level is more than the number of
          # tags, we return the last tag.
          if level >= output.length
            output.last
          else
            output[level - 1]
          end
        end

        private

        def sorted_tags_for_edition
          Gitlab::Util.shellout_stdout("git -c versionsort.prereleaseSuffix=rc tag -l '#{tag_match_pattern}' --sort=-v:refname")&.split("\n")
        end

        def tag_match_pattern
          return '*[+.]ee.*' if Build::Check.is_ee?

          '*[+.]ce.*'
        end
      end
    end
  end
end
