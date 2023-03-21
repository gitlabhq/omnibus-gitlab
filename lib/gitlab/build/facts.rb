module Build
  class Facts
    class << self
      def generate
        generate_tag_files
        generate_version_files
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

      def get_component_shas(version_manifest_file = 'version-manifest.json')
        return {} unless File.exist?(version_manifest_file)

        version_manifest = JSON.parse(File.read(version_manifest_file))
        softwares = version_manifest['software']
        results = {}
        Gitlab::Version::COMPONENTS_ENV_VARS.keys.map do |component|
          next unless softwares.key?(component)

          results[component] = softwares[component]['locked_version']
        end

        results
      end

      def generate_version_files
        # Do not build version facts for tags and stable branches because
        # those jobs MUST use the VERSION files
        return if Build::Check.on_tag? || Build::Check.on_stable_branch?

        get_component_shas('build_facts/version-manifest.json').each do |component, sha|
          File.write("build_facts/#{component}_version", sha) unless sha.nil?
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
          BUILDER_IMAGE_REVISION=#{Gitlab::Util.get_env('BUILDER_IMAGE_REVISION')}
          BUILDER_IMAGE_REGISTRY=#{Gitlab::Util.get_env('BUILDER_IMAGE_REGISTRY')}
          PUBLIC_BUILDER_IMAGE_REGISTRY=#{Gitlab::Util.get_env('PUBLIC_BUILDER_IMAGE_REGISTRY')}
          COMPILE_ASSETS=#{Gitlab::Util.get_env('COMPILE_ASSETS') || 'false'}
          EDITION=#{Build::Info.edition.upcase}
          ee=#{Build::Check.is_ee? || 'false'}
        ]
      end

      def qa_trigger_vars
        %W[
          QA_RELEASE=#{Build::GitlabImage.gitlab_registry_image_address(tag: Build::Info.docker_tag)}
          QA_IMAGE=#{Build::Info.qa_image}
          QA_TESTS=#{Gitlab::Util.get_env('QA_TESTS')}
          ALLURE_JOB_NAME=#{allure_job_name}-#{Build::Info.edition}
          GITLAB_SEMVER_VERSION=#{Build::Info.latest_stable_tag.tr('+', '-')}
          RAT_REFERENCE_ARCHITECTURE=#{Gitlab::Util.get_env('RAT_REFERENCE_ARCHITECTURE') || 'omnibus-gitlab-mrs'}
          RAT_FIPS_REFERENCE_ARCHITECTURE=#{Gitlab::Util.get_env('RAT_FIPS_REFERENCE_ARCHITECTURE') || 'omnibus-gitlab-mrs-fips-ubuntu'}
          RAT_PACKAGE_URL=#{Gitlab::Util.get_env('PACKAGE_URL') || Build::Info.triggered_build_package_url(fips: false)}
          RAT_FIPS_PACKAGE_URL=#{Gitlab::Util.get_env('FIPS_PACKAGE_URL') || Build::Info.triggered_build_package_url(fips: true)}
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

      def allure_job_name
        (upstream_project || Gitlab::Util.get_env('CI_PROJECT_NAME')).split('/').last
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
