require_relative '../../util'
require_relative 'components'
require_relative 'package'

module Build
  class Info
    class QA
      class << self
        def image
          Gitlab::Util.get_env('QA_IMAGE') || "#{Gitlab::Util.get_env('CI_REGISTRY')}/#{Build::Info::Components::GitLabRails.project_path}/#{Build::Info::Package.name}-qa:#{Build::Info::Components::GitLabRails.ref(prepend_version: false)}"
        end
      end
    end
  end
end
