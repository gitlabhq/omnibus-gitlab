if Dir.exist?(File.absolute_path(File.join(__dir__, "../../gitlab-jh")))
  include_recipe 'gitlab-jh::default'
elsif Dir.exist?(File.absolute_path(File.join(__dir__, "../../gitlab-ee")))
  include_recipe 'gitlab-ee::default'
elsif Dir.exist?(File.absolute_path(File.join(__dir__, "../../gitlab")))
  include_recipe 'gitlab::default'
end
