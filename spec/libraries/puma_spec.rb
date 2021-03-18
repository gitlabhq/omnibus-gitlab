require 'chef_helper'

RSpec.describe 'Puma' do
  let(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { ::Redis }
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '.only_one_allowed!' do
    context 'with default configuration' do
      it 'does not raise an error' do
        expect { chef_run }.not_to raise_error
      end
    end

    context 'with user specified values' do
      using RSpec::Parameterized::TableSyntax

      where(:puma_enabled, :unicorn_enabled, :expect_error) do
        true  | false | false
        true  | true  | true
        false | true  | false
        nil   | true  | true
      end

      with_them do
        before do
          final_config = {}

          final_config[:puma] = { enable: puma_enabled } unless puma_enabled.nil?
          final_config[:unicorn] = { enable: unicorn_enabled } unless unicorn_enabled.nil?

          stub_gitlab_rb(final_config)
        end

        if params[:expect_error]
          it 'raises an error' do
            expect { chef_run }.to raise_error("Only one web server (Puma or Unicorn) can be enabled at the same time!")
          end
        else
          it 'does not raise any errors' do
            expect { chef_run }.not_to raise_error
          end
        end
      end
    end
  end
end
