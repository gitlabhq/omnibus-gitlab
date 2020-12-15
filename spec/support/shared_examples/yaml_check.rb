require 'yaml'

shared_examples 'renders a valid YAML file' do |filename|
  it 'parses YAML with no errors' do
    expect(chef_run).to render_file(filename).with_content { |content|
      expect { YAML.parse(content) }.not_to raise_error
    }
  end
end
