require 'spec_helper'
require 'gitlab/package_repository'

RSpec.describe PackageRepository do
  describe '.new' do
    it 'returns a PulpRepository instance' do
      expect(PackageRepository.new).to be_a(PackageRepository::PulpRepository)
    end
  end
end
