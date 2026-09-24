require 'spec_helper'

# Guards the single point of control for Go FIPS builds.
# https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/10091
#
# GOFIPS140 is exported once from omnibus.rb, so no Go component opts in. A
# component may only opt out, and that has to stay a deliberate, reviewable
# act rather than a line that quietly reappears in every recipe.

# Definitions allowed to override the central export, mapped to the reason. A
# bypass must set GOFIPS140 to 'off', Go's own value for the in-tree crypto
# packages, and carry a justification comment.
bypasses = {}.freeze

RSpec.describe 'Go FIPS module in software definitions' do
  project_root = File.expand_path('../../../..', __dir__)

  describe 'omnibus.rb' do
    it 'exports the Go FIPS module centrally' do
      expect(File.read(File.join(project_root, 'omnibus.rb'))).to include('Build::Check.export_go_fips_module_env!')
    end
  end

  describe 'config/software' do
    definitions = Dir.glob(File.join(project_root, 'config', 'software', '*.rb')).sort

    it 'finds software definitions to check' do
      expect(definitions).not_to be_empty
    end

    definitions.each do |path|
      name = File.basename(path, '.rb')

      it "#{name} does not set GOFIPS140 itself" do
        # Comments are free to mention GOFIPS140. Only code that sets it counts.
        offending = File.readlines(path).each_with_index
                        .reject { |line, _index| line.strip.start_with?('#') }
                        .select { |line, _index| line.include?('GOFIPS140') }

        if bypasses.key?(name)
          expect(offending.map(&:first).join).to include("'off'"),
                                                 "#{name} is allowlisted as a GOFIPS140 bypass, so it must set GOFIPS140 to 'off'"
        else
          expect(offending).to be_empty,
                               "#{name} sets GOFIPS140, which is exported centrally from omnibus.rb. A component only " \
                               "opts out, by setting GOFIPS140 to 'off' with a justification comment and adding itself " \
                               "to `bypasses` in spec/lib/gitlab/build/go_fips_definitions_spec.rb. Offending lines: " \
                               "#{offending.map { |line, index| "#{index + 1}: #{line.strip}" }.join(', ')}"
        end
      end
    end
  end
end
