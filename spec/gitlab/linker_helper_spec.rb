require 'spec_helper'
require 'gitlab/linker_helper'

RSpec.describe LinkerHelper do
  subject(:service) { described_class }
  before do
    allow(IO).to receive(:popen).and_call_original
    allow(IO).to receive(:popen).with(%w[ldconfig -p]).and_return("1 library found\nlibssl.so (libc6,x86-64) => /lib64/libssl.so")
  end

  describe "#ldconfig" do
    it "should should update linker cache" do
      expect(service).to receive(:system).with("ldconfig")

      service.ldconfig
    end

    it "should return discovered libraries" do
      expect(service.ldconfig).to have_key("libssl.so")
    end
  end
end
