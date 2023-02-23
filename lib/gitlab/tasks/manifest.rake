require_relative '../manifest/uploader.rb'
require_relative '../manifest/collector.rb'

namespace :manifest do
  desc "Generate version manifest file of current release and push to AWS bucket"
  task :upload do
    Gitlab::Util.section('manifest:upload') do
      # This is done on Ubuntu 18.04 non-rc tag pipeline only
      Manifest::Uploader.new.execute unless Build::Check.is_rc_tag?
    end
  end

  desc "Collect all manifest files and generate index page"
  task :generate_pages do
    Gitlab::Util.section('manifest:generate_pages') do
      Manifest::Collector.new.execute
    end
  end
end
