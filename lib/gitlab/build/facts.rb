module Build
  class Facts
    class << self
      def generate
        generate_tag_files
        generate_env_file
      end

      def generate_tag_files
        [
          :latest_stable_tag,
          :latest_tag
        ].each do |fact|
          content = Build::Info.send(fact) # rubocop:disable GitlabSecurity/PublicSend
          File.write("build_facts/#{fact}", content) unless content.nil?
        end
      end

      def generate_env_file
        env_vars = []
        env_vars += common_vars
        env_vars += qa_trigger_vars
        env_vars += omnibus_trigger_vars

        File.write("build_facts/env_vars", env_vars.join("\n"))
      end

      def common_vars
        %W[
          TOP_UPSTREAM_SOURCE_PROJECT=#{Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_PROJECT') || Gitlab::Util.get_env('CI_PROJECT_PATH')}
          TOP_UPSTREAM_SOURCE_REF=#{Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_REF') || Gitlab::Util.get_env('CI_COMMIT_REF_NAME')}
          TOP_UPSTREAM_SOURCE_JOB=#{Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_JOB') || Gitlab::Util.get_env('CI_JOB_URL')}
          TOP_UPSTREAM_SOURCE_SHA=#{Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_SHA') || Gitlab::Util.get_env('CI_COMMIT_SHA')}
          TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID=#{Gitlab::Util.get_env('TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID')}
          TOP_UPSTREAM_MERGE_REQUEST_IID=#{Gitlab::Util.get_env('TOP_UPSTREAM_MERGE_REQUEST_IID')}
          EDITION=#{Build::Info.edition}
          ee=#{Build::Check.is_ee? || 'false'}
        ]
      end

      def qa_trigger_vars
        %W[
          QA_BRANCH=#{Gitlab::Util.get_env('QA_BRANCH') || 'master'}
          QA_RELEASE=#{Build::GitlabImage.gitlab_registry_image_address(tag: Build::Info.docker_tag)}
          QA_IMAGE=#{Gitlab::Util.get_env('QA_IMAGE') || Build::QAImage.gitlab_registry_image_address(tag: Build::Info.docker_tag)}
          QA_TESTS=#{Gitlab::Util.get_env('QA_TESTS')}
          ALLURE_JOB_NAME=#{Gitlab::Util.get_env('ALLURE_JOB_NAME')}
          GITLAB_QA_OPTIONS=#{Gitlab::Util.get_env('GITLAB_QA_OPTIONS')}
          KNAPSACK_GENERATE_REPORT=#{generate_knapsack_report?}
        ]
      end

      def omnibus_trigger_vars
        version_vars
      end

      def version_vars
        Gitlab::Version::COMPONENTS_ENV_VARS.values.uniq.map do |version|
          "#{version}=#{Gitlab::Util.get_env(version)}"
        end
      end

      private

      def generate_knapsack_report?
        (upstream_project == "gitlab-org/gitlab" && upstream_ref == "master").to_s
      end

      def upstream_project
        Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_PROJECT')
      end

      def upstream_ref
        Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_REF')
      end
    end
  end
end
