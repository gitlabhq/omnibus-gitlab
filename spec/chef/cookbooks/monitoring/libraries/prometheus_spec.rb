require 'chef_helper'

RSpec.describe Prometheus do
  before { Services.add_services('gitlab', Services::BaseServices.list) }

  it 'should return a list of known services' do
    expect(Prometheus.services).to match_array(%w(
                                                 prometheus
                                                 alertmanager
                                                 node_exporter
                                                 redis_exporter
                                                 postgres_exporter
                                                 gitlab_exporter
                                               ))
  end
end
