require 'chef_helper'

describe 'go_crond_job' do
  context 'go-crond enabled' do
    let(:runner) do
      ChefSpec::SoloRunner.new(step_into: %w(go_crond_job)) do |node|
        node.normal['go-crond']['cron_d'] = "prefix"
      end
    end

    context 'delete' do
      let(:chef_run) { runner.converge("go-crond::enable", "test_go_crond_job::delete") }

      it 'should delete the file' do
        expect(chef_run).to delete_file("prefix/delete")
      end

      it 'should notify the service' do
        expect(chef_run.file("prefix/delete"))
          .to notify("service[go-crond]").to(:restart)
      end
    end

    context 'minimal' do
      let(:chef_run) { runner.converge("go-crond::enable", "test_go_crond_job::minimal") }

      it 'should set up the file' do
        expect(chef_run).to create_file("prefix/minimal").with(
          owner: "root",
          content: "* * * * * rspec echo 'Hello world'\n"
        )
      end

      it 'should notify the service' do
        expect(chef_run.file("prefix/minimal"))
          .to notify("service[go-crond]").to(:restart)
      end
    end
  end

  context 'go-crond disabled' do
    let(:runner) do
      ChefSpec::SoloRunner.new(step_into: %w(go_crond_job)) do |node|
        node.normal['go-crond']['cron_d'] = "prefix"
      end
    end

    context 'delete' do
      let(:chef_run) { runner.converge("test_go_crond_job::delete") }

      it 'should delete the file' do
        expect(chef_run).to delete_file("prefix/delete")
      end

      it 'should not try and notify the service' do
        expect(chef_run.file("prefix/delete"))
          .not_to notify("service[go-crond]")
      end
    end

    context 'minimal' do
      let(:chef_run) { runner.converge("test_go_crond_job::minimal") }

      it 'should not set up the file' do
        expect(chef_run).not_to create_file("prefix/minimal")
      end
    end
  end
end
