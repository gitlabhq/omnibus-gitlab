require_relative '../glibc_checker'

namespace :build do
  namespace :health_check do
    desc 'Check GLIBC versions in all .so files'
    task :glibc do
      Gitlab::Util.section('build:health_check:glibc') do
        Gitlab::GlibcChecker.check_all
      end
    end
  end
end
