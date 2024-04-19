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

    # TODO: When multi-arch images are built by default, modify `platforms`
    # array to include `linux/arm64` also
    def build(location, image, tag, dockerfile: nil, buildargs: nil, platforms: %w[linux/amd64], push: true)
      create_builder

      commands = %W[docker buildx build #{location} -t #{image}:#{tag}]

      if (env_var_platforms = Gitlab::Util.get_env('DOCKER_BUILD_PLATFORMS'))
        platforms.append(env_var_platforms.split(",").map(&:strip))
      end

      platforms.uniq!

      commands += %W[--platform=#{platforms.join(',')}]

      # If specified to push, we must push to registry. Even if not, if the
      # image being built is multiarch, we must push to registry.
      commands += %w[--push] if push || platforms.length > 1

      commands += %W[-f #{dockerfile}] if dockerfile

      buildargs&.each do |arg|
        commands += %W[--build-arg='#{arg}']
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
  end
end
