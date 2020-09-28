require 'spec_helper'
require_relative '../../files/gitlab-cookbooks/package/libraries/helpers/output_helper'

RSpec.describe OutputHelper do
  include OutputHelper

  describe "#quote" do
    context 'handling nil' do
      it 'should return nil' do
        expect(quote(nil)).to eq(nil)
      end
    end

    context 'handling numbers' do
      it 'should cooerce numbers to strings' do
        result = quote(42)
        expect(result).to be_instance_of(String)
        expect(result).to eq('"42"')
      end
    end

    context 'roundtripping values via YAML' do
      values = [
        "foo",
        # single quotes
        "foo'",
        "'foo",
        "fo'o",
        "'foo'",
        # double quotes
        'foo"',
        '"foo',
        'fo"o',
        '"foo"',
        # newlines
        "foo\n",
        "\nfoo",
        "fo\no",
        "\nfoo\n",
        # tabs
        "foo\t",
        "\tfoo",
        "fo\to",
        "\tfoo\t",
        # spaces
        "foo ",
        " foo",
        "fo o",
        " foo ",
        # unicode snowman
        "foo☃",
        "☃foo",
        "fo☃o",
        "☃foo☃",
      ]
      values.each do |value|
        it "should YAML roundtrip #{value.inspect}" do
          # create a document with structure { 'value' : quote(value) }
          yaml_document = "---\nvalue: #{quote(value)}"
          document = YAML.safe_load(yaml_document)
          expect(document['value']).to eq(value)
        end
      end
    end
  end
end
