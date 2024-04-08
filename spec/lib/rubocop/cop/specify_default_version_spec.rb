require 'spec_helper'
require 'rubocop/rspec/cop_helper'
require 'rubocop/rspec/expect_offense'

require 'rubocop/cop/specify_default_version'

RSpec.describe Rubocop::Cop::SpecifyDefaultVersion do
  include CopHelper
  include RuboCop::RSpec::ExpectOffense

  subject(:cop) { described_class.new }

  it 'flags violation for software definition files without default_version set' do
    expect_offense(<<~RUBY)
    name 'sample'
    ^{} Specify default_version for the component.

    license 'MIT'

    build do
      make
      make install
    end
    RUBY
  end

  it 'does not flag violation for software definition files with default_version set' do
    expect_no_offenses(<<~RUBY)
    name 'sample'

    license 'MIT'

    default_version '1.0.0'

    build do
      make
      make install
    end
    RUBY
  end
end
