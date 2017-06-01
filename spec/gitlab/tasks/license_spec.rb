require 'chef_helper'

describe 'license:check', type: :rake do
  before :all do
    Rake.application.rake_require 'gitlab/tasks/license_check'
  end

  before do
    Rake::Task['license:check'].reenable
    @license_info = '{
      "chef-zero": {
        "version": "4.8.0",
        "license": "Apache-2.0"
      },
      "bar": {
        "version": "2.3.0",
        "license": "jargon"
      },
      "foo": {
        "version": "1.2.11",
        "license": "GPL-3.0+"
      }
    }'
    allow(File).to receive(:exist?).and_return(true)
  end

  it 'detects good licenses correctly' do
    allow(File).to receive(:read).and_return(@license_info)
    expect { Rake::Task['license:check'].invoke }.to output(/Good.*chef-zero - 4.8.0.*Apache-2.0/).to_stdout
  end

  it 'detects bad licenses correctly' do
    allow(File).to receive(:read).and_return(@license_info)
    expect { Rake::Task['license:check'].invoke }.to output(/Check.*foo - 1.2.11.*GPL-3.0\+/).to_stdout
  end

  it 'detects unknown licenses correctly' do
    allow(File).to receive(:read).and_return(@license_info)
    expect { Rake::Task['license:check'].invoke }.to output(/Unknown.*bar - 2.3.0.*jargon/).to_stdout
  end

  it 'should detect if install directory not found' do
    allow(File).to receive(:read).and_return('install_dir   /opt/gitlab')
    allow(File).to receive(:exist?).with('/opt/gitlab').and_return(false)
    expect { Rake::Task['license:check'].invoke }.to raise_error(StandardError, "Unable to retrieve install_dir, thus unable to check /opt/gitlab/dependency_licenses.json")
  end

  it 'should detect if dependency_license.json file not found' do
    allow(File).to receive(:read).and_return('install_dir   /opt/gitlab')
    allow(File).to receive(:exist?).with('/opt/gitlab').and_return(true)
    allow(File).to receive(:exist?).with('/opt/gitlab/dependency_licenses.json').and_return(false)
    expect { Rake::Task['license:check'].invoke }.to raise_error(StandardError, "Unable to open /opt/gitlab/dependency_licenses.json")
  end
end
