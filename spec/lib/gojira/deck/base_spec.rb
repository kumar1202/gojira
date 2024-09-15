# frozen_string_literal: true

require 'open3'
require 'gojira/deck/base'

RSpec.describe Gojira::Deck::Base do
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

  describe '#param_string' do
    it 'generates the correct parameter string' do
      expected_params = "--kong-addr #{kong_addr} --config-file #{config_file} --timeout #{timeout} " \
                        "--ca-cert-file #{tls_params[:ca_cert_file]} --tls-client-cert-file #{tls_params[:tls_client_cert_file]} --tls-client-key-file #{tls_params[:tls_client_key_file]} --tls-server-name #{tls_params[:tls_server_name]}"
      expect(subject.send(:param_string)).to eq(expected_params.strip)
    end
  end

  describe '#execute' do
    let(:command) { 'your_command' }

    context 'when command executes successfully' do
      it 'captures stdout and returns output' do
        allow(Open3).to receive(:capture3).and_return(['output', '', double(success?: true)])
        subject.execute(command)
        expect(subject.instance_variable_get(:@output)).to eq(['output'])
        expect(subject.error).to be_empty
      end
    end

    context 'when command fails' do
      it 'captures stderr and sets error' do
        allow(Open3).to receive(:capture3).and_return(['', 'error message', double(success?: false)])
        subject.execute(command)
        expect(subject.instance_variable_get(:@output)).to be_empty
        expect(subject.error).to eq(['Error executing command: error message'])
      end
    end
  end
end
