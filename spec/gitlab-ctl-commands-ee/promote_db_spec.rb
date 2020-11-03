# frozen_string_literal: true

require 'spec_helper'
require 'geo/promote_db'

RSpec.describe 'gitlab-ctl promote-db' do
  let(:klass) { Geo::PromoteDb }
  let(:command_name) { 'promote-db' }
  let(:command_script) { 'promote_db' }

  include_context 'ctl'

  it_behaves_like 'gitlab geo promotion commands', 'promote-db'
end
