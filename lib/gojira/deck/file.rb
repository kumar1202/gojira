# frozen_string_literal: true

module Gojira
  module Deck
    class File < Gojira::Deck::Base
      def initialize(binary_path, kong_addr = nil, config_file = nil, timeout = nil, tls_params = {})
        super
      end

      def lint(state_file, ruleset_file)
        command = "file lint -s #{state_file} #{ruleset_file}"
        execute(command)
      end

      def render(state_file_list, output_file)
        command = "file render #{state_file_list.join(' ')} -o #{output_file}"
        execute(command)
      end

      def merge(state_file_list, output_file)
        command = "file merge -o #{output_file} #{state_file_list.join(' ')}"
        execute(command)
      end

      def validate(state_file)
        command = "file validate -o #{state_file}"
        execute(command)
      end
    end
  end
end
