require 'chef_helper'

RSpec.describe PgStatusHelper do
  cached(:chef_run) { converge_config }
  let!(:node) { chef_run.node }
  let!(:helper) { PgHelper.new(node) }
  let(:connection_info) { helper.build_connection_info('dbname', 'dbhost', 'port', 'pguser') }

  context 'when checking status' do
    subject { described_class.new(connection_info, node) }

    describe '#service_checks_exhausted?' do
      it 'returns true when there are zero remaining service checks' do
        allow(subject).to receive(:remaining_service_checks).and_return(0)
        expect(subject.service_checks_exhausted?).to be true
      end

      it 'returns false when more service checks are allowed' do
        allow(subject).to receive(:remaining_service_checks).and_return(1)
        expect(subject.service_checks_exhausted?).to be false
      end
    end

    describe '#ready?' do
      it 'raises no warnings when Postgres is accepting connections' do
        allow(subject).to receive(:accepting_connections?).and_return(true)
        expect(subject.ready?).to be true
      end

      it 'raises a warning when Postgres is not responding' do
        allow(subject).to receive(:not_responding?).and_return(true)
        allow(subject).to receive(:remaining_service_checks).and_return(0)
        expect { subject.ready? }.to raise_error(RuntimeError, 'PostgreSQL did not respond before service checks were exhausted')
      end

      it 'raises a warning when Postgres gets invalid connection parameters' do
        allow(subject).to receive(:invalid_connection_parameters?).and_return(true)
        expect { subject.ready? }.to raise_error(RuntimeError, 'PostgreSQL is not receiving the correct connection parameters')
      end

      it 'raises a warning when all service checks are exhausted' do
        allow(subject).to receive(:service_checks_exhausted?).and_return(true)
        expect { subject.ready? }.to raise_error(RuntimeError, 'Exhausted service checks and database is still not available')
      end
    end

    context 'when invoking pg_isready' do
      using RSpec::Parameterized::TableSyntax

      where(:exit_code, :accepting, :rejecting, :not_responding, :invalid_parameters) do
        0 | true | false | false | false
        1 | false | true | false | false
        2 | false | false | true | false
        3 | false | false | false | true
      end

      with_them do
        before do
          result = spy('shellout')
          allow(subject).to receive(:do_shell_out).and_return(result)
          allow(result).to receive(:exitstatus).and_return(exit_code)
        end

        describe '#service_state' do
          it 'returns the expected exit code' do
            expect(subject.service_state).to eq(exit_code)
          end
        end

        describe '#accepting_connections?' do
          it 'returns the expected boolean' do
            expect(subject.accepting_connections?).to be accepting
          end
        end

        describe '#rejecting_connections?' do
          it 'returns the expected boolean' do
            expect(subject.rejecting_connections?).to be rejecting
          end
        end

        describe '#not_responding?' do
          it 'returns the expected boolean' do
            expect(subject.not_responding?).to be not_responding
          end
        end

        describe '#invalid_connection_parameters?' do
          it 'returns the expected boolean' do
            expect(subject.invalid_connection_parameters?).to be invalid_parameters
          end
        end
      end
    end
  end

  context 'when all checks use configured defaults' do
    subject { described_class.new(connection_info, node) }

    describe '#maximum_service_checks' do
      it 'will check 20 times' do
        expect(subject.maximum_service_checks).to eq(20)
      end
    end

    describe '#service_check_interval' do
      it 'will check every 5 seconds' do
        expect(subject.service_check_interval).to eq(5)
      end
    end
  end

  context 'when checks are are customized' do
    let(:the_answer) { 424242 }
    before do
      chef_run.node.normal['postgresql']['max_service_checks'] = the_answer
      chef_run.node.normal['postgresql']['service_check_interval'] = the_answer
      @subject = described_class.new(connection_info, node)
    end

    describe '#maximum_service_checks' do
      it 'will check the configured number of times' do
        expect(@subject.maximum_service_checks).to eq(the_answer)
      end
    end

    describe '#service_check_interval' do
      it 'will check at a configured interval' do
        expect(@subject.service_check_interval).to eq(the_answer)
      end
    end
  end
end
