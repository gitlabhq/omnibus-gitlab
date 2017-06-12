require 'docker'

class DockerOperations
  def self.build(location, image, tag)
    Docker.options[:read_timeout] = 600
    Docker::Image.build_from_dir(location.to_s, { t: "#{image}:#{tag}", pull: true }) do |chunk|
      if (log = JSON.parse(chunk)) && log.key?("stream")
        puts log["stream"]
      end
    end
  end

  def self.authenticate(username, password, serveraddress)
    Docker.authenticate!(username: username, password: password, serveraddress: serveraddress)
  end

  def self.push(image_id, old_tag, new_tag, repo = "gitlab")
    image = Docker::Image.get("#{image_id}:#{old_tag}")
    image.info["RepoTags"].pop
    image.tag(repo: "#{repo}/#{image_id}", tag: new_tag, force: true)
    image.push(Docker.creds, repo_tag: "#{repo}/#{image_id}:#{new_tag}") do |chunk|
      puts chunk
    end
  end
end
