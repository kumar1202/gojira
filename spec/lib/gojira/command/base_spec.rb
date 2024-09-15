# frozen_string_literal: true

require 'thor'
require 'gojira/command/base'

RSpec.describe Gojira::Command::Base do
  describe '.banner' do
    context 'when subcommand is false' do
      let(:command) { double('Command', usage: 'command [OPTIONS]') }

      it 'generates the correct banner without subcommand prefix' do
        expect(described_class.banner(command)).to eq('rspec base command [OPTIONS]')
      end
    end
  end

  describe '.subcommand_prefix' do
    it 'generates the correct subcommand prefix for Pascal case class name' do
      class TestSubCommand < Gojira::Command::Base; end
      expect(TestSubCommand.subcommand_prefix).to eq('test-sub-command')
    end

    it 'generates the correct subcommand prefix for acronyms in class name' do
      class XMLParser < Gojira::Command::Base; end
      expect(XMLParser.subcommand_prefix).to eq('xml-parser')
    end
  end
end
