require 'chef_helper'

RSpec.describe Prometheus do
  before { Services.add_services('gitlab', Services::BaseServices.list) }

  it 'should return a list of known services' do
    expect(Prometheus.services).to match_array(%w(
                                                 prometheus
                                                 alertmanager
                                                 grafana
                                                 node-exporter
                                                 redis-exporter
                                                 postgres-exporter
                                                 gitlab-exporter
                                               ))
  end
end
