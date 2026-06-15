require 'chef_helper'

RSpec.describe PgHelper do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  describe '#public_attributes' do
    it 'exposes the postgresql attributes the rest of the system reads at runtime' do
      attrs = subject.public_attributes

      expect(attrs).to have_key('postgresql')
      expect(attrs['postgresql']).to include('dir', 'unix_socket_directory', 'port')
    end

    it 'returns plain Hash/Array values that the report handler can deep_merge!' do
      attrs = subject.public_attributes

      # Regression: nested Mash values caused
      # Chef::Exceptions::ImmutableAttributeModification in the
      # GitLabHandler::Attributes report handler. We deep-clone via JSON
      # to keep the returned structure mutable.
      target = {}
      expect do
        Chef::Mixin::DeepMerge.deep_merge!(attrs, target)
      end.not_to raise_error
      expect(target['postgresql']).to include('dir', 'unix_socket_directory', 'port')
    end

    context 'when postgresql.component_databases is populated' do
      before do
        chef_run.node.normal['postgresql']['component_databases'] = {
          'gate' => {
            'enable' => true,
            'database' => 'gate_production',
            'user' => 'gate',
            'password' => 'md5deadbeef',
            'extensions' => ['pg_trgm']
          }
        }
      end

      after do
        chef_run.node.rm_normal('postgresql', 'component_databases')
      end

      it 'includes component_databases in the exposed surface' do
        attrs = subject.public_attributes
        expect(attrs['postgresql']).to have_key('component_databases')
        expect(attrs['postgresql']['component_databases']).to have_key('gate')
        expect(attrs['postgresql']['component_databases']['gate']['database']).to eq('gate_production')
      end

      it 'returns mutable Hashes for nested component_databases entries' do
        attrs = subject.public_attributes
        target = {}
        expect do
          Chef::Mixin::DeepMerge.deep_merge!(attrs, target)
        end.not_to raise_error
        # The deep-merge target carries the allow-list sub-fields;
        # the secret-field exclusion is pinned in the scrubbing
        # regression below.
        expect(target['postgresql']['component_databases']['gate']['database']).to eq('gate_production')
      end

      it 'scrubs secret-shaped fields from each entry' do
        # public_attributes.json is world-readable; the allow-list
        # constant restricts the exposed shape to `enable` and
        # `database` so the md5(password+username) hash never leaves
        # the chef node tree.
        attrs = subject.public_attributes
        entry = attrs['postgresql']['component_databases']['gate']

        expect(entry.keys).to contain_exactly('enable', 'database')
        expect(entry).not_to have_key('password')
        expect(entry).not_to have_key('user')
        expect(entry).not_to have_key('extensions')
      end

      it 'ignores non-Hash entries defensively' do
        chef_run.node.normal['postgresql']['component_databases']['bogus'] = 'not a hash'

        attrs = subject.public_attributes

        expect(attrs['postgresql']['component_databases']).to have_key('gate')
        expect(attrs['postgresql']['component_databases']).not_to have_key('bogus')
      end
    end
  end
end
