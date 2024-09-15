# frozen_string_literal: true

require 'open3'
require 'gojira/deck/file'

RSpec.describe Gojira::Deck::Gateway do
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

  describe '#sync' do
    it 'executes sync command with correct parameters' do
      state_file = 'state_file.yaml'
      expected_command = "gateway sync #{state_file}"

      expect(subject).to receive(:execute).with(expected_command)
      subject.sync(state_file)
    end
  end

  describe '#validate' do
    it 'executes validate command with correct parameters' do
      state_file = 'state_file.yaml'
      expected_command = "gateway validate #{state_file}"

      expect(subject).to receive(:execute).with(expected_command)
      subject.validate(state_file)
    end
  end

  describe '#diff' do
    it 'executes diff command with correct parameters' do
      state_file = 'state_file.yaml'
      expected_command = "gateway diff #{state_file}"

      expect(subject).to receive(:execute).with(expected_command)
      subject.diff(state_file)
    end
  end

  describe '#dump' do
    it 'executes dump command with correct parameters' do
      expected_command = 'gateway dump'

      expect(subject).to receive(:execute).with(expected_command)
      subject.dump
    end
  end
end
