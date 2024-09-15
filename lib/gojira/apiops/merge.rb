# frozen_string_literal: true

module Gojira
  module APIOps
    class Merge
      attr_accessor :errors
      attr_reader :gateway_folder, :env_dir, :cluster_file

      def initialize
        @gateway_folder = gateway_folder
        @env_dir = env_dir
        @cluster_file = cluster_file
        @errors = []
      end

      def execute
      end
    end
  end
end
