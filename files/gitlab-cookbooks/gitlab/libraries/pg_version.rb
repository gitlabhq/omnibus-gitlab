#
# Copyright:: Copyright (c) 2018 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class PGVersion < String
  attr_reader :major, :minor

  VERSION_PATTERN ||= %r{
    \A(?<part1>\d+)
    (\.(?<part2>\d+))?
    (\.(?<part3>\d+))?\z
  }x.freeze

  def initialize(version_string)
    super(version_string)
    parse_version_parts
  end

  def self.parse(version_string)
    new(version_string) if version_string
  end

  def valid?
    self.class::VERSION_PATTERN.match?(self) && !!major
  end

  private

  def parse_version_parts
    match_data = self.class::VERSION_PATTERN.match(self)
    return unless match_data

    part1 = match_data[:part1].to_i
    part2 = match_data[:part2].to_i if match_data.names.include?('part2') && match_data[:part2]
    part3 = match_data[:part3].to_i if match_data.names.include?('part3') && match_data[:part3]

    # Prior the Postgres 10, the major version was considered the first two parts
    # eg. 9.6, with 10, just 10 is considered the major version
    # https://www.postgresql.org/support/versioning/
    if part1 >= 10
      @major = part1.to_s
      @minor = part2.to_s if part2
    else
      @major = "#{part1}.#{part2}" if part2
      @minor = part3.to_s if part3
    end
  end
end
