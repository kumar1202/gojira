# frozen_string_literal: true

require 'thor'
require 'gojira/cli'

RSpec.describe Gojira::CLI do
  let(:cli) { described_class.new }

  describe '#version' do
    it 'prints the gem version' do
      expect { cli.version }.to output("#{Gojira::VERSION}\n").to_stdout
    end
  end

  describe 'subcommands' do
    it 'has subcommand for cluster' do
      expect(described_class.subcommands).to include('cluster')
    end

    it 'has subcommand for env' do
      expect(described_class.subcommands).to include('env')
    end
  end

  describe 'cluster subcommand' do
    it 'executes cluster subcommand correctly' do
      expect_any_instance_of(Gojira::Command::Cluster).to receive(:sync)
      cli.options = {kong_state_file: "state.yaml", env_name: "production", compliance_type: "pci", cluster_file: "clusters.yaml", dc_name: "nm"}
      #require 'pry'; binding.pry
      cli.invoke('cluster', ["sync"], {kong_state_file: "state.yaml", env_name: "production", compliance_type: "pci", cluster_file: "clusters.yaml", dc_name: "nm"})
    end
  end

  describe 'env subcommand' do
    it 'executes env subcommand correctly' do
      expect_any_instance_of(Gojira::Command::Env).to receive(:lint)
      cli.invoke('env', ['lint'])
    end
  end
end
