class WatchHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def watcher_config(watcher)
    {
      watches: [
        {
          type: 'service',
          service: watcher,
          args: ["#{@node['consul']['script_directory']}/#{watcher_handler(watcher)}"]
        }
      ]
    }
  end

  def watcher_handler(watcher)
    node['consul']['watcher_config'][watcher]['handler']
  end
end
