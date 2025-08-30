# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Gojira
  module APIOps
    class Merge
      attr_accessor :errors, :output_file
      attr_reader :gateway_folder, :env_name, :cluster_file, :compliance_type, :dc_name

      def initialize(gateway_folder, env_name, cluster_file, compliance_type, dc_name)
        @gateway_folder = gateway_folder
        @env_name = env_name
        @cluster_file = cluster_file
        @compliance_type = compliance_type
        @dc_name = dc_name
        @errors = []
        @output_file = nil
      end

      def execute
        validate_inputs
        return if @errors.any?

        merged_config = {
          '_format_version' => '3.0',
          'services' => [],
          'upstreams' => [],
          'routes' => []
        }

        # Load cluster configuration
        clusters = load_cluster_config
        return if @errors.any?

        # Get environment path
        env_path = File.join(@gateway_folder, @env_name)
        unless Dir.exist?(env_path)
          @errors << "Environment directory does not exist: #{env_path}"
          return
        end

        # Process each product directory
        product_dirs = Dir.entries(env_path).select do |entry|
          path = File.join(env_path, entry)
          File.directory?(path) && !entry.start_with?('.')
        end

        product_dirs.each do |product|
          product_path = File.join(env_path, product)
          
          # Load upstreams configuration
          upstreams_file = File.join(product_path, 'upstreams.yaml')
          upstreams_config = load_upstreams(upstreams_file) if File.exist?(upstreams_file)
          
          # Process service files
          service_files = Dir.glob(File.join(product_path, '*.yaml')).reject { |f| f.end_with?('upstreams.yaml') }
          
          service_files.each do |service_file|
            process_service_file(service_file, upstreams_config, merged_config)
          end
        end

        # Generate output file
        output_dir = File.join(@gateway_folder, 'generated')
        FileUtils.mkdir_p(output_dir)
        
        @output_file = File.join(output_dir, "kong-#{@env_name}-#{@compliance_type}-#{@dc_name}.yaml")
        
        File.write(@output_file, merged_config.to_yaml)
      end

      private

      def validate_inputs
        unless @gateway_folder && Dir.exist?(@gateway_folder)
          @errors << "Gateway folder does not exist: #{@gateway_folder}"
        end

        unless @env_name && !@env_name.empty?
          @errors << "Environment name is required"
        end

        unless @compliance_type && !@compliance_type.empty?
          @errors << "Compliance type is required"
        end

        unless @dc_name && !@dc_name.empty?
          @errors << "Data center name is required"
        end
      end

      def load_cluster_config
        return {} unless @cluster_file && File.exist?(@cluster_file)

        begin
          clusters = YAML.load_file(@cluster_file)
          
          unless clusters[@env_name]
            @errors << "Environment '#{@env_name}' not found in cluster file"
            return {}
          end

          env_config = clusters[@env_name]
          
          # Verify DC exists in configuration
          if env_config['dc'] && !env_config['dc'].include?(@dc_name)
            @errors << "Data center '#{@dc_name}' not found in environment configuration"
          end

          clusters
        rescue Psych::SyntaxError => e
          @errors << "Invalid YAML in cluster file: #{e.message}"
          {}
        end
      end

      def load_upstreams(upstreams_file)
        begin
          YAML.load_file(upstreams_file) || {}
        rescue Psych::SyntaxError => e
          @errors << "Invalid YAML in upstreams file #{upstreams_file}: #{e.message}"
          {}
        end
      end

      def process_service_file(service_file, upstreams_config, merged_config)
        begin
          content = YAML.load_file(service_file)
          return unless content && content['services']

          content['services'].each do |service|
            # Filter by compliance type
            next unless service['tags'] && service['tags'].include?(@compliance_type)

            # Clone service to avoid modifying original
            processed_service = service.dup
            processed_service['routes'] = []

            # Process routes
            if service['routes']
              service['routes'].each do |route|
                processed_route = route.dup
                processed_route['service'] = { 'name' => service['name'] }
                merged_config['routes'] << processed_route
              end
            end

            # Remove routes from service object
            processed_service.delete('routes')
            
            merged_config['services'] << processed_service

            # Process upstream if exists
            if service['host'] && upstreams_config[service['host']]
              upstream = create_upstream(service['name'], service['host'], upstreams_config[service['host']])
              merged_config['upstreams'] << upstream if upstream
            end
          end
        rescue Psych::SyntaxError => e
          @errors << "Invalid YAML in service file #{service_file}: #{e.message}"
        rescue => e
          @errors << "Error processing service file #{service_file}: #{e.message}"
        end
      end

      def create_upstream(service_name, upstream_name, upstream_config)
        # Find targets for the specified DC
        dc_config = upstream_config.find { |config| config.is_a?(Hash) && config[@dc_name] }
        return nil unless dc_config

        targets = dc_config[@dc_name]
        return nil unless targets && targets.is_a?(Array)

        {
          'name' => upstream_name,
          'targets' => targets.map do |target|
            {
              'target' => "#{target['host']}:#{target['port'] || 443}",
              'weight' => target['weight']
            }
          end,
          'hash_on' => 'none',
          'hash_fallback' => 'none',
          'hash_on_cookie_path' => '/',
          'slots' => 10000,
          'healthchecks' => {
            'passive' => {
              'type' => 'http',
              'unhealthy' => {
                'http_statuses' => [429, 500, 503],
                'http_failures' => 5,
                'interval' => 0
              },
              'healthy' => {
                'http_statuses' => [200, 201, 202, 203, 204, 205, 206, 207, 208, 226,
                                   300, 301, 302, 303, 304, 305, 306, 307, 308],
                'successes' => 0
              }
            }
          }
        }
      end
    end
  end
end