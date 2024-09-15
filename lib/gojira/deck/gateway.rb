# frozen_string_literal: true

module Gojira
  module Deck
    class Gateway < Gojira::Deck::Base
      def initialize(binary_path = 'deck', kong_addr = nil, config_file = nil, timeout = nil, tls_params = {})
        super
      end

      def sync(state_file)
        command = "gateway sync #{state_file}"
        execute(command)
      end

      def diff(state_file)
        command = "gateway diff #{state_file}"
        execute(command)
      end

      def dump
        command = 'gateway dump'
        execute(command)
      end

      def validate(state_file)
        command = "gateway validate #{state_file}"
        execute(command)
      end
    end
  end
end
