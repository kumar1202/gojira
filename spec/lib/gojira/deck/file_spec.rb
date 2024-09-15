# frozen_string_literal: true

require 'open3'
require 'gojira/deck/file'

RSpec.describe Gojira::Deck::File do
  let(:binary_path) { 'binary' }
  let(:kong_addr) { 'http://localhost:8000' }
  let(:config_file) { 'config.yml' }
  let(:timeout) { 10 }
  let(:tls_params) do
    {
      ca_cert_file: 'ca_cert.pem',
      tls_client_cert_file: 'client_cert.pem',
      tls_client_key_file: 'client_key.pem',
      tls_server_name: 'kong.com'
    }
  end

  subject { described_class.new(binary_path, kong_addr, config_file, timeout, tls_params) }

  describe '#initialize' do
    it 'initializes with correct attributes' do
      expect(subject.binary_path).to eq(binary_path)
      expect(subject.params[:kong_addr]).to eq(kong_addr)
      expect(subject.params[:config_file]).to eq(config_file)
      expect(subject.params[:timeout]).to eq(timeout)
      expect(subject.params[:tls_params]).to eq(tls_params)
      expect(subject.error).to be_empty
    end
  end

  describe '#lint' do
    it 'executes lint command with correct parameters' do
      state_file = 'state_file.yaml'
      ruleset_file = 'ruleset_file.yaml'
      expected_command = "file lint -s #{state_file} #{ruleset_file}"

      expect(subject).to receive(:execute).with(expected_command)
      subject.lint(state_file, ruleset_file)
    end
  end

  describe '#render' do
    it 'executes render command with correct parameters' do
      state_file_list = ['state_file1.yaml', 'state_file2.yaml']
      output_file = 'output_file.yaml'
      expected_command = "file render #{state_file_list.join(' ')} -o #{output_file}"

      expect(subject).to receive(:execute).with(expected_command)
      subject.render(state_file_list, output_file)
    end
  end

  describe '#merge' do
    it 'executes merge command with correct parameters' do
      state_file_list = ['state_file1.yaml', 'state_file2.yaml']
      output_file = 'output_file.yaml'
      expected_command = "file merge -o #{output_file} #{state_file_list.join(' ')}"

      expect(subject).to receive(:execute).with(expected_command)
      subject.merge(state_file_list, output_file)
    end
  end

  describe '#validate' do
    it 'executes validate command with correct parameters' do
      state_file = 'state_file.yaml'
      expected_command = "file validate -o #{state_file}"

      expect(subject).to receive(:execute).with(expected_command)
      subject.validate(state_file)
    end
  end
end
