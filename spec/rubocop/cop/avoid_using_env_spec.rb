require 'spec_helper'
require 'rubocop'
require_relative '../../../lib/rubocop/cop/avoid_using_env'
require_relative '../../support/rubocop_helper.rb'

RSpec.describe Rubocop::Cop::AvoidUsingEnv do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags violation for setting env vars directly' do
    expect_offense(<<~RUBY)
      call do
        ENV['foo'] = 'blah'
        ^^^^^^^^^^^^^^^^^^^ Do not use ENV directly to set environment variables, use Gitlab::Util.set_env or Gitlab::Util.set_env_if_missing methods instead.
      end
    RUBY
  end

  it 'flags violation for getting env vars directly ENV' do
    expect_offense(<<~RUBY)
      call do
      value = ENV['foo']
              ^^^^^^^^^^ Do not use ENV directly to retrieve environment variables. Use Gitlab::Util.get_env method instead.
      end
    RUBY
  end

  it 'flags violation for using ||= with ENV' do
    expect_offense(<<~RUBY)
      call do
      ENV['bar'] ||= ENV['foo']
                     ^^^^^^^^^^ Do not use ENV directly to retrieve environment variables. Use Gitlab::Util.get_env method instead.
      ^^^^^^^^^^ Do not use ENV directly to retrieve environment variables. Use Gitlab::Util.get_env method instead.
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use ENV directly to set environment variables, use Gitlab::Util.set_env or Gitlab::Util.set_env_if_missing methods instead.
      end
    RUBY
  end

  it 'does not flag violation for comments' do
    expect_no_offenses(<<~RUBY)
      call do
      # ENV['bar'] ||= ENV['foo']
      puts valu
      end
    RUBY
  end
end
