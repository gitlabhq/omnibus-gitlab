require 'docker'

class DockerOperations
  def self.remove_containers
    puts 'Removing existing containers'
    containers = Docker::Container.all
    containers.each do |container|
      begin
        container.delete(v: true)
      rescue
        next
      end
    end
  end

  def self.remove_dangling_images
    puts 'Removing dangling images'
    dangling_images = Docker::Image.all(filters: '{"dangling":[ "true" ]}')
    dangling_images.each do |image|
      begin
        image.remove
      rescue
        next
      end
    end
  end

  def self.remove_existing_images(release_package)
    puts 'Removing existing images'
    images = Docker::Image.all
    images.each do |image|
      next unless image.info["RepoTags"][0].include?(release_package)
      begin
        image.remove(force: true)
      rescue
        next
      end
    end
  end
end
