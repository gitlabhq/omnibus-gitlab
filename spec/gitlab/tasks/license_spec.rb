require 'chef_helper'

describe 'license:check', type: :rake do
  before :all do
    Rake.application.rake_require 'gitlab/tasks/license_check'
  end

  before :each do
    Rake::Task['license:check'].reenable
  end

  it 'should identify good licenses' do
    string = 'This product bundles chef-zero 4.8.0,
which is available under a "Apache-2.0" License.
Details:

                              Apache License
                        Version 2.0, January 2004
                     http://www.apache.org/licenses/
'

    allow(File).to receive(:exists?).and_return(true)
    allow(File).to receive(:read).and_return(string)
    expect { Rake::Task['license:check'].invoke }.to output(/Good.*chef-zero 4.8.0.*Apache-2.0/).to_stdout
  end

  it 'should identify bad licenses' do
    string = 'This product bundles foo 4.8.0,
which is available under a "GPL-3.0+" License.
Details:
'
    allow(File).to receive(:exists?).and_return(true)
    allow(File).to receive(:read).and_return(string)
    expect { Rake::Task['license:check'].invoke }.to output(/Check.*foo 4.8.0.*GPL-3.0\+/).to_stdout
  end

  it 'should detect unidentified licenses' do
    string = 'This product bundles foo 4.8.0,
which is available under a "jargon" License.
Details:
'
    allow(File).to receive(:exists?).and_return(true)
    allow(File).to receive(:read).and_return(string)
    expect { Rake::Task['license:check'].invoke }.to output(/Unknown.*foo 4.8.0.*jargon/).to_stdout

  end

  it 'should detect weird line-breaks' do
    string = 'This product bundles chef-zero 4.8.0
,
which is available under a "Apache-2.0" License.
Details:

                              Apache License
                        Version 2.0, January 2004
                     http://www.apache.org/licenses/
'
    allow(File).to receive(:exists?).and_return(true)
    allow(File).to receive(:read).and_return(string)
    expect { Rake::Task['license:check'].invoke }.to output(/Good.*chef-zero 4.8.0.*Apache-2.0/).to_stdout

  end

  it 'should detect if install directory not found' do
    allow(File).to receive(:read).and_return('install_dir   /opt/gitlab')
    allow(File).to receive(:exists?).with('/opt/gitlab').and_return(false)
    expect { Rake::Task['license:check'].invoke }.to raise_error(StandardError).with_message("Unable to retrieve install_dir, thus unable to check /opt/gitlab/LICENSE")
  end

  it 'should detect if LICENSE file not found' do
    allow(File).to receive(:read).and_return('install_dir   /opt/gitlab')
    allow(File).to receive(:exists?).with('/opt/gitlab').and_return(true)
    allow(File).to receive(:exists?).with('/opt/gitlab/LICENSE').and_return(false)
    expect { Rake::Task['license:check'].invoke }.to raise_error(StandardError).with_message("Unable to open /opt/gitlab/LICENSE")
  end
end
