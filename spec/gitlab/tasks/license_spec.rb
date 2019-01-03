require 'spec_helper'

describe 'license:check', type: :rake do
  let(:f) { double("Mocked file object") }

  before :all do
    Rake.application.rake_require 'gitlab/tasks/license'
  end

  before do
    Rake::Task['license:check'].reenable
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(/pkg.*license-status.json/, "w").and_return(f)
    allow(f).to receive(:write).and_return(true)
    allow(f).to receive(:close).and_return(true)
    allow(Build::Info).to receive(:release_version).and_return("11.5.1+ce.0")
  end

  it 'detects good licenses correctly' do
    license_info = '[
      {
        "name": "chef-zero",
        "version": "4.8.0",
        "license": "Apache-2.0",
        "dependencies": [
          {
            "name": "sample",
            "version": "1.0.0",
            "license": "MIT"
          }
        ]
      }
     ]'
    allow(File).to receive(:read).and_return(license_info)

    expect { Rake::Task['license:check'].invoke }.to output(/✓.*chef-zero - 4.8.0.*Apache-2.0/).to_stdout
  end

  it 'detects blacklisted softwares with good licenses correctly' do
    license_info = '[
      {
        "name": "readline",
        "version": "4.8.0",
        "license": "Apache-2.0",
        "dependencies": [
          {
            "name": "sample",
            "version": "1.0.0",
            "license": "MIT"
          }
        ]
      }
     ]'
    allow(File).to receive(:read).and_return(license_info)

    expect { Rake::Task['license:check'].invoke }.to output(/readline.*Blacklisted software/).to_stdout.and raise_error(RuntimeError, "Build Aborted due to license violations")
  end

  it 'detects bad licenses correctly' do
    license_info = '[
      {
        "name": "foo",
        "version": "4.8.0",
        "license": "GPL-3.0",
        "dependencies": [
          {
            "name": "sample",
            "version": "1.0.0",
            "license": "GPL-3.0"
          }
        ]
      }
     ]'

    allow(File).to receive(:read).and_return(license_info)
    expect { Rake::Task['license:check'].invoke }.to output(/foo.*Unacceptable license/).to_stdout.and raise_error(RuntimeError, "Build Aborted due to license violations")
  end

  it 'detects whitelisted softwares with bad licenses correctly' do
    license_info = '[
      {
        "name": "git",
        "version": "4.8.0",
        "license": "GPL-3.0",
        "dependencies": [
          {
            "name": "sample",
            "version": "1.0.0",
            "license": "LGPL"
          }
        ]
      }
     ]'
    allow(File).to receive(:read).and_return(license_info)

    expect { Rake::Task['license:check'].invoke }.to output(/git.*Whitelisted software/).to_stdout
  end

  it 'detects blacklisted softwares with unknown licenses correctly' do
    license_info = '[
      {
        "name": "readline",
        "version": "4.8.0",
        "license": "jargon",
        "dependencies": [
          {
            "name": "sample",
            "version": "1.0.0",
            "license": "MIT"
          }
        ]
      }
     ]'
    allow(File).to receive(:read).and_return(license_info)

    expect { Rake::Task['license:check'].invoke }.to output(/readline.*Blacklisted software/).to_stdout.and raise_error(RuntimeError, "Build Aborted due to license violations")
  end

  it 'detects whitelisted software with unknown licenses correctly' do
    license_info = '[
      {
        "name": "git",
        "version": "4.8.0",
        "license": "jargon",
        "dependencies": [
          {
            "name": "sample",
            "version": "1.0.0",
            "license": "MIT"
          }
        ]
      }
     ]'
    allow(File).to receive(:read).and_return(license_info)
    expect { Rake::Task['license:check'].invoke }.to output(/git.*Whitelisted software/).to_stdout
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
