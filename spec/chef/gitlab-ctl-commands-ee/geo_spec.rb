# frozen_string_literal: true

require 'spec_helper'
require 'omnibus-ctl'
require 'optparse'

require_relative('../../../files/gitlab-ctl-commands/lib/gitlab_ctl')
require_relative('../../../files/gitlab-ctl-commands-ee/lib/geo')

RSpec.describe 'gitlab-ctl geo' do
  commands = %w(promote)

  command_lines = {
    'promote' => []
  }

  command_options = {
    'promote' => {}
  }

  describe '.parse_options' do
    before do
      allow(Geo::Utils).to receive(:warn_and_exit).and_call_original
      allow(Kernel).to receive(:exit) { |code| raise "Kernel.exit(#{code})" }
      allow(Kernel).to receive(:warn)
    end

    it 'throws an error when global options are invalid' do
      expect { Geo.parse_options(%w(geo --foo)) }.to raise_error(OptionParser::ParseError)
    end

    it 'throws an error when sub-command is not specified' do
      expect { Geo.parse_options(%w(geo -v)) }.to raise_error(OptionParser::ParseError)
    end

    it 'throws an error when sub-command is not defined' do
      expect { Geo.parse_options(%w(geo -v foo)) }.to raise_error(OptionParser::ParseError)
    end

    it 'recognizes global options' do
      expect(Geo.parse_options(%w(geo -v -q promote))).to include(quiet: true, verbose: true)
    end

    context 'when sub-command is passed' do
      commands.each do |cmd|
        it "parses #{cmd} options" do
          cmd_line = command_lines[cmd] || []
          cmd_opts = command_options[cmd] || {}
          cmd_opts[:command] = cmd

          expect(Geo.parse_options(%W(geo #{cmd}) + cmd_line)).to include(cmd_opts)
        end
      end
    end

    context 'when help option is passed' do
      it 'shows help message and exit for global help option' do
        expect { Geo.parse_options(%w(geo -h)) }.to raise_error('Kernel.exit(0)')
        expect(Geo::Utils).to have_received(:warn_and_exit).with(/Usage help/)
      end

      commands.each do |cmd|
        it "shows help message and exit for #{cmd} help option" do
          expect { Geo.parse_options(%W(geo #{cmd} -h)) }.to raise_error('Kernel.exit(0)')
          expect(Geo::Utils).to have_received(:warn_and_exit).with(instance_of(OptionParser))
        end
      end
    end
  end
end
