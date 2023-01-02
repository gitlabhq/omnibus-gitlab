require 'retriable'
require 'open3'

class SkopeoHelper
  ImageNotFoundError = Class.new(StandardError)

  class << self
    def login(username, password, registry)
      status = Open3.popen3({}, *%W[skopeo login --tls-verify --username=#{username} --password-stdin #{registry}]) do |stdin, stdout, stderr, wait_thr|
        stdin.puts(password)
        stdin.close

        wait_thr.value
      end

      raise "Failed to login to #{registry}" unless status.success?

      puts "Successfully logged in to #{registry}."
    end

    def copy_image(source, target)
      print "Waiting for source image `#{source}` to be available"
      # Retries for up to 15 minutes (900 seconds)
      Retriable.retriable(tries: 30, max_elapsed_time: 900, on: ImageNotFoundError) do
        Open3.popen2e(*%W[skopeo inspect docker://#{source}]) do |_, stdout_stderr, status|
          print "."

          # To prevent buffer from filling up and execution to hang, force a
          # read from it.
          stdout_stderr.read

          raise ImageNotFoundError, "Image `#{source}` not found." unless status.value.success?
        end
      end

      puts "\nCopying image `#{source}` to `#{target}`"
      status = system(*%W[skopeo copy docker://#{source} docker://#{target}])

      raise "Failed to copy image." unless status
    end
  end
end
