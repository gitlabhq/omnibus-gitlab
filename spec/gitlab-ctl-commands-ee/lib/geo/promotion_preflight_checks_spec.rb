require 'spec_helper'
require 'fileutils'
require 'geo/promotion_preflight_checks'
require 'gitlab_ctl/util'

describe Geo::PromotionPreflightChecks, '#execute' do
  subject(:command) { described_class.new }

  let(:confirmation) { 'y' }

  before do
    allow(STDIN).to receive(:gets).and_return(confirmation)
  end

  it 'prints preflight check instructions' do
    expect { command.execute }.to output(
      /Ensure you have completed the following manual preflight checks/)
      .to_stdout
  end

  context 'when confirmation is accepted' do
    it 'does not raise an error' do
      expect { command.execute }.to_not raise_error
    end
  end

  context 'when confirmation is not accepted' do
    let(:confirmation) { 'n' }

    around do |example|
      example.run
    rescue SystemExit
    end

    it 'print error message' do
      expect { command.execute }.to output(
        /ERROR: Manual preflight checks were not performed/
      ).to_stdout
    end
  end
end
