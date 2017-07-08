require 'chef_helper'

describe Prometheus do
  it 'should return a list of known services' do
    expect(Prometheus.services).to match_array(%w(
                                                 prometheus
                                                 node-exporter
                                                 redis-exporter
                                                 postgres-exporter
                                                 gitlab-monitor
                                               ))
  end
end
