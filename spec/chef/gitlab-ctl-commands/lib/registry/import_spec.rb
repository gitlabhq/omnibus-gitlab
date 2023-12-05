require 'optparse'

require_relative('../../../../../files/gitlab-ctl-commands/lib/registry/import')

RSpec.describe Import do
  describe '.parse_options!' do
    before do
      allow(Kernel).to receive(:exit) { |code| raise "Kernel.exit(#{code})" }
    end

    options_data = [
      [:common_blobs, 'common-blobs', false],
      [:row_count, 'row-count', false],
      [:dry_run, 'dry-run', false],
      [:empty, 'require-empty-database', false],
      [:pre_import, 'pre-import', false],
      [:all_repositories, 'all-repositories', true],
      [:step_one, 'step-one', false],
      [:step_two, 'step-two', true],
      [:step_three, 'step-three', false]
    ]

    options_data.each do |option, option_name, read_only|
      it "correctly parses the #{option_name} option#{' with read-only mode' if read_only}" do
        expected_options = { option => "--#{option_name}" }
        expected_options[:needs_read_only] = true if read_only

        result = Import.parse_options!(%W[import --#{option_name}], OptionParser.new, {})
        expect(result).to eq(expected_options)
      end
    end
  end
end
