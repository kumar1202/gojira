# frozen_string_literal: true

module Gojira
  module APIOps
    class Validations
      attr_accessor :errors
      attr_reader :gateway_folder, :env_dir, :cluster_file

      def initialize(gateway_folder, env_dir, cluster_file)
        @gateway_folder = gateway_folder
        @env_dir = env_dir
        @cluster_file = cluster_file
        @errors = []
      end

      def execute
        validate_env
        validate_cluster_file
        validate_env_dir
        validate_service
        validate_upstreams
      end

      def validate_env
        Dir.open(@gateway_folder + @env_dir)
        # Check env name if is allowed
      end

      def validate_cluster_file
        # Check if all env have defined DCs and each DC have pci and npci control planes
      end

      def validate_env_dir
        # check the structure of the env dir:
          # product_group -> one or more services
          # product_group has a valid upstreams file
        # figure out if any unknown files are present
      end

      def validate_service(service_file)
        # Check if only one service is defined per file
        # Check if the correct pci/non-pci tag is present on the service
        # Check if routes don't have tags
        # Check if 
      end

      def validate_upstreams(upstreams_file)
        # Check if upstreams for all services in the product_group is present or not
        # Check if both pci and non-pci upstreams for a service are defined
        # Check if all targets of a given upstream add up to 100
      end
    end
  end
end
