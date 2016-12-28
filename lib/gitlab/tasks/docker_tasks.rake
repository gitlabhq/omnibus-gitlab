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
      begin
        container.delete(:v => true)
      rescue
        next
      end
    end
    dangling_images = Docker::Image.all(:filters => '{"dangling":[ "true" ]}')
    dangling_images.each do |image|
      begin
        image.remove
      rescue
        next
      end
    end
    images = Docker::Image.all
    images.each do |image|
      if image.info["RepoTags"][0].include?(RELEASE_PACKAGE)
        begin
          image.remove(:force => true)
        rescue
          next
        end
      end
    end
  end

  desc "Push Docker Image to Registry"
  task :push, [:RELEASE_PACKAGE] do |_t, args|
    DOCKER_TAG = ENV["DOCKER_TAG"]
    RELEASE_PACKAGE = args['RELEASE_PACKAGE']
    puts DOCKER_TAG
    puts RELEASE_PACKAGE
    image = Docker::Image.create(:fromImage => "#{RELEASE_PACKAGE}:latest")
    image.tag(:repo => "gitlab/#{RELEASE_PACKAGE}", :tag => "#{DOCKER_TAG}", :force => true)
    image.push(:tag => "#{DOCKER_TAG}")
  end
end
