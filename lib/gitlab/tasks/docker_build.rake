require 'docker'

namespace :docker do
  desc "Build Docker image"
  task :build, [:RELEASE_PACKAGE] do |_t, args|
    RELEASE_PACKAGE = args['RELEASE_PACKAGE']
    location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
    Docker::Image.build_from_dir("#{location}", {:t => "#{RELEASE_PACKAGE}:latest", :pull => true })
  end

  desc "Clean Docker stuff"
  task :clean, [:RELEASE_PACKAGE] do |_t, args|
    RELEASE_PACKAGE = args['RELEASE_PACKAGE']
    containers = Docker::Container.all
    containers.each do |container|
      container.delete(:force => true, :v => true)
    end
    dangling_images = Docker::Image.all(:filters => '{"dangling":[ "true" ]}')
    dangling_images.each do |image|
      image.remove
    end
    images = Docker::Image.all
    images.each do |image|
      if image.info["RepoTags"][0].include?(RELEASE_PACKAGE)
        image.remove
      end
    end
  end
end
