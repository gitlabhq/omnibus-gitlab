require 'open3'
require_relative 'docker_operations'

# TODO: Deprecate DockerOperations
class DockerHelper < DockerOperations
  class << self
    def authenticate(username: nil, password: nil, registry: nil)
      puts "Logging in to Docker registry"

      stdout, stderr, status = Open3.popen3({}, *%W[docker login --username=#{username} --password-stdin #{registry}]) do |stdin, stdout, stderr, wait_thr|
        stdin.puts(password)
        stdin.close

        [stdout.read, stderr.read, wait_thr.value]
      end

      return if status.success?

      puts "Failed to login to Docker registry."
      puts "Output is: #{stdout}"
      puts stderr
      Kernel.exit 1
    end

    def build(location, image, tag, dockerfile: nil, buildargs: nil, arch: Gitlab::Util.get_env('DOCKER_ARCH'), push: true)
      create_builder

      commands = %W[docker buildx build #{location} -t #{image}:#{tag}]

      # We need to specify a platform so that TARGETARCH variable is populated
      arch ||= 'amd64'
      commands += %W[--platform=linux/#{arch}]

      commands += %w[--push] if push

      commands += %W[-f #{dockerfile}] if dockerfile

      buildargs&.each do |arg|
        commands += %W[--build-arg #{arg}]
      end

      puts "Running command: #{commands.join(' ')}"

      Open3.popen2e(*commands) do |_, stdout_stderr, status|
        while line = stdout_stderr.gets
          puts line
        end

        Kernel.exit 1 unless status.value.success?
      end
    end

    def create_builder
      cleanup_existing_builder

      puts "Creating docker builder instance"
      # TODO: For multi-arch builds, use Kubernetes driver for builder instance
      _, stdout_stderr, status = Open3.popen2e(*%w[docker buildx create --bootstrap --use --name omnibus-gitlab-builder])

      return if status.value.success?

      puts "Creating builder instance failed."
      puts "Output: #{stdout_stderr.read}"
      raise
    end

    def cleanup_existing_builder
      puts "Cleaning any existing builder instances."
      _, _, status = Open3.popen2e(*%w[docker buildx ls | grep omnibus-gitlab-builder])
      unless status.value.success?
        puts "omnibus-gitlab-builder instance not found. Not attempting to clean."
        return
      end

      _, stdout_stderr, status = Open3.popen2e(*%w[docker buildx rm --force omnibus-gitlab-builder])
      if status.value.success?
        puts "Successfully cleaned omnibus-gitlab-builder instance."
      else
        puts "Cleaning of omnibus-gitlab-builder instance failed."
        puts "Output: #{stdout_stderr.read}"
      end
    end

    def combine_images(name, tag, tag_list)
      destination_image = "#{name}:#{tag}"
      source_images = [].tap do |sources|
        tag_list.each do |input_tag|
          sources << "#{name}:#{input_tag}"
        end
      end

      commands = %W[docker buildx imagetools create -t #{destination_image}] + source_images
      commands.flatten

      puts "Running command: #{commands.join(' ').inspect}"

      Open3.popen2e(*commands) do |_, stdout_stderr, status|
        while line = stdout_stderr.gets
          puts line
        end

        Kernel.exit 1 unless status.value.success?
      end
    end
  end
end
