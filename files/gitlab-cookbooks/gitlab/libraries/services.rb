class Services
  class << self
    def service_list
      @service_list ||= {
        'gitlab-rails' =>       { groups: ['default'] },
        'unicorn' =>            { groups: ['default'] },
        'sidekiq' =>            { groups: ['default'] },
        'postgresql' =>         { groups: ['default'] },
        'redis' =>              { groups: ['default'] },
        'gitlab-workhorse' =>   { groups: ['default'] },
        'nginx' =>              { groups: ['default'] },
        'logrotate' =>          { groups: ['default'] },
        'prometheus' =>         { groups: ['default'] },
        'node-exporter' =>      { groups: ['default'] },
        'redis-exporter' =>     { groups: ['default'] },
        'postgres-exporter' =>  { groups: ['default'] },
        'gitaly' =>             { groups: ['default'] },
        'gitlab-monitor' =>     { groups: ['default'] },
        'mailroom' =>           { groups: [] },
        'gitlab-pages' =>       { groups: [] },
        'mattermost' =>         { groups: [] },
        'mattermost-nginx' =>   { groups: [] },
        'pages-nginx' =>        { groups: [] },
        'registry' =>           { groups: [] },
      }
    end
  end
end
