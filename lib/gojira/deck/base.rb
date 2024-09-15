# frozen_string_literal: true

require 'open3'

module Gojira
  module Deck
    class Base
      attr_reader :binary_path, :params
      attr_accessor :output, :error

      def initialize(binary_path, kong_addr = nil, config_file = nil, timeout = 10, tls_params = {})
        @binary_path = binary_path
        @params = {
          kong_addr: kong_addr,
          config_file: config_file,
          timeout: timeout,
          tls_params: tls_params
        }
        @output = []
        @error = []
      end

      def execute(command)
        stdout_str, stderr_str, status = Open3.capture3("#{@binary_path} #{command} #{param_string}")
        @output << stdout_str.chomp and return if status.success?

        @error << "Error executing command: #{stderr_str}"
      end

      protected

      def param_string
        "#{generate_param_string(params.except(:tls_params))} #{generate_param_string(params[:tls_params])}"
      end

      def generate_param_string(params)
        params.map { |key, value| "--#{key.to_s.gsub('_', '-')} #{value}" unless value.nil? }.join(' ').strip
      end
    end
  end
end
