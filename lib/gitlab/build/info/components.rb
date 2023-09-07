require_relative '../../util'
require_relative '../check'

module Build
  class Info
    class Components
      class GitLabRails
        class << self
          def name
            Build::Info::Package.name == "gitlab-ce" ? "gitlab-rails" : "gitlab-rails-ee"
          end

          def version
            # Get the branch/version/commit of GitLab CE/EE repo against which package
            # is built. If GITLAB_VERSION variable is specified, as in triggered builds,
            # we use that. Else, we use the value in VERSION file.

            if Gitlab::Util.get_env('GITLAB_VERSION').nil? || Gitlab::Util.get_env('GITLAB_VERSION').empty?
              File.read('VERSION').strip
            else
              Gitlab::Util.get_env('GITLAB_VERSION')
            end
          end

          def version_slug
            version.downcase
              .gsub(/[^a-z0-9]/, '-')[0..62]
              .gsub(/(\A-+|-+\z)/, '')
          end

          def ref(prepend_version: true)
            # Returns the immutable git ref of GitLab rails being used.
            #
            # 1. In feature branch pipelines, generate-facts job will create
            #    version fact files which will contain the commit SHA of GitLab
            #    rails. This will be used by `Gitlab::Version` class and will be
            #    presented as version of `gitlab-rails` software component.
            # 2. In stable branch and tag pipelines, these version fact files will
            #    not be created. However, in such cases, VERSION file will be
            #    anyway pointing to immutable references (git tags), and hence we
            #    can directly use it.
            Gitlab::Version.new(name).print(prepend_version)
          end

          def project_path
            if Gitlab::Util.get_env('CI_SERVER_HOST') == 'dev.gitlab.org'
              Build::Info::Package.name == "gitlab-ee" ? 'gitlab/gitlab-ee' : 'gitlab/gitlabhq'
            else
              namespace = Gitlab::Version.security_channel? ? "gitlab-org/security" : "gitlab-org"
              project = Build::Info::Package.name == "gitlab-ee" ? 'gitlab' : 'gitlab-foss'

              "#{namespace}/#{project}"
            end
          end

          def repo
            Gitlab::Version.new(name).remote
          end
        end
      end
    end
  end
end
