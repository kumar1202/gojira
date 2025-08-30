# frozen_string_literal: true

require 'yaml'

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
      end

      def validate_env
        env_path = File.join(@gateway_folder, @env_dir)
        unless Dir.exist?(env_path)
          @errors << "Environment directory does not exist: #{env_path}"
          return
        end
        
        # Check if env name matches directory structure
        env_name = @env_dir.split('/').first
        unless env_name && env_name.match?(/^[a-zA-Z0-9_-]+$/)
          @errors << "Invalid environment name: #{env_name}. Must contain only alphanumeric characters, hyphens, and underscores."
        end
      end

      def validate_cluster_file
        return unless @cluster_file
        
        unless File.exist?(@cluster_file)
          @errors << "Cluster file does not exist: #{@cluster_file}"
          return
        end
        
        begin
          clusters = YAML.load_file(@cluster_file)
          unless clusters.is_a?(Hash)
            @errors << "Cluster file must contain a YAML hash/dictionary"
            return
          end
          
          env_name = @env_dir.split('/').first
          unless clusters[env_name]
            @errors << "Environment '#{env_name}' not found in cluster file"
            return
          end
          
          env_config = clusters[env_name]
          
          # Validate DC list
          unless env_config['dc'] && env_config['dc'].is_a?(Array) && !env_config['dc'].empty?
            @errors << "Environment '#{env_name}' must have a 'dc' array with at least one data center"
          end
          
          # Validate control planes
          unless env_config['control_plane'] && env_config['control_plane'].is_a?(Array)
            @errors << "Environment '#{env_name}' must have a 'control_plane' array"
            return
          end
          
          # Check each DC has at least one control plane
          if env_config['dc']
            env_config['dc'].each do |dc|
              dc_control_planes = env_config['control_plane'].select { |cp| cp['dc'] == dc }
              
              if dc_control_planes.empty?
                @errors << "Data center '#{dc}' has no control plane configurations"
              end
            end
          end
          
          # Validate control plane entries
          env_config['control_plane'].each do |cp|
            unless cp['compliance_type'] && !cp['compliance_type'].to_s.strip.empty?
              @errors << "Control plane entry missing compliance_type"
            end
            
            unless cp['dc'] && cp['address']
              @errors << "Control plane entry missing required fields (dc, address)"
            end
          end
          
        rescue Psych::SyntaxError => e
          @errors << "Invalid YAML in cluster file: #{e.message}"
        end
      end

      def validate_env_dir
        env_path = File.join(@gateway_folder, @env_dir)
        return unless Dir.exist?(env_path)
        
        # Get all product directories
        product_dirs = Dir.entries(env_path).select do |entry|
          path = File.join(env_path, entry)
          File.directory?(path) && !entry.start_with?('.')
        end
        
        if product_dirs.empty?
          @errors << "No product directories found in environment: #{@env_dir}"
          return
        end
        
        product_dirs.each do |product|
          product_path = File.join(env_path, product)
          
          # Check for upstreams.yaml
          upstreams_file = File.join(product_path, 'upstreams.yaml')
          unless File.exist?(upstreams_file)
            @errors << "Missing upstreams.yaml in product directory: #{product}"
          else
            validate_upstreams(upstreams_file)
          end
          
          # Check for service files
          service_files = Dir.glob(File.join(product_path, '*.yaml')).reject { |f| f.end_with?('upstreams.yaml') }
          
          if service_files.empty?
            @errors << "No service files found in product directory: #{product}"
          else
            service_files.each { |service_file| validate_service(service_file) }
          end
          
          # Check for unknown files
          all_files = Dir.entries(product_path).reject { |f| f.start_with?('.') }
          yaml_files = all_files.select { |f| f.end_with?('.yaml') || f.end_with?('.yml') }
          non_yaml_files = all_files - yaml_files - ['.', '..']
          
          unless non_yaml_files.empty?
            @errors << "Unknown non-YAML files in product directory #{product}: #{non_yaml_files.join(', ')}"
          end
        end
      end

      def validate_service(service_file)
        begin
          content = YAML.load_file(service_file)
          
          unless content && content['services']
            @errors << "Service file #{service_file} must contain 'services' key"
            return
          end
          
          services = content['services']
          unless services.is_a?(Array)
            @errors << "'services' in #{service_file} must be an array"
            return
          end
          
          # Check if only one service is defined per file
          if services.length != 1
            @errors << "Service file #{service_file} must contain exactly one service, found #{services.length}"
          end
          
          services.each do |service|
            # Validate service structure
            unless service['name']
              @errors << "Service in #{service_file} missing required 'name' field"
            end
            
            unless service['host']
              @errors << "Service '#{service['name']}' in #{service_file} missing required 'host' field"
            end
            
            # Check for tags
            if !service['tags'] || !service['tags'].is_a?(Array)
              @errors << "Service '#{service['name']}' in #{service_file} must have 'tags' array"
            elsif service['tags'].empty?
              @errors << "Service '#{service['name']}' in #{service_file} must have at least one tag"
            end
            
            # Check routes
            if service['routes'] && service['routes'].is_a?(Array)
              service['routes'].each_with_index do |route, index|
                unless route['name']
                  @errors << "Route at index #{index} in service '#{service['name']}' missing 'name' field"
                end
                
                # Routes should not have tags
                if route['tags'] && !route['tags'].empty?
                  @errors << "Route '#{route['name']}' in service '#{service['name']}' should not have tags"
                end
              end
            end
          end
          
        rescue Psych::SyntaxError => e
          @errors << "Invalid YAML in service file #{service_file}: #{e.message}"
        rescue => e
          @errors << "Error validating service file #{service_file}: #{e.message}"
        end
      end

      def validate_upstreams(upstreams_file)
        begin
          upstreams = YAML.load_file(upstreams_file)
          
          unless upstreams && upstreams.is_a?(Hash)
            @errors << "Upstreams file #{upstreams_file} must contain a YAML hash/dictionary"
            return
          end
          
          product_dir = File.dirname(upstreams_file)
          service_files = Dir.glob(File.join(product_dir, '*.yaml')).reject { |f| f.end_with?('upstreams.yaml') }
          
          # Collect all service hosts
          service_hosts = []
          service_files.each do |service_file|
            begin
              content = YAML.load_file(service_file)
              if content && content['services'] && content['services'].is_a?(Array)
                content['services'].each do |service|
                  service_hosts << service['host'] if service['host']
                end
              end
            rescue => e
              # Skip if can't read service file
            end
          end
          
          # Check if upstreams exist for all services
          service_hosts.uniq.each do |host|
            unless upstreams[host]
              @errors << "Missing upstream definition for service host '#{host}' in #{upstreams_file}"
            end
          end
          
          # Validate each upstream
          upstreams.each do |upstream_name, dc_configs|
            unless dc_configs.is_a?(Array)
              @errors << "Upstream '#{upstream_name}' must be an array of DC configurations"
              next
            end
            
            dc_configs.each do |dc_config|
              unless dc_config.is_a?(Hash) && dc_config.size == 1
                @errors << "Invalid DC configuration format for upstream '#{upstream_name}'"
                next
              end
              
              dc_name = dc_config.keys.first
              targets = dc_config[dc_name]
              
              unless targets.is_a?(Array)
                @errors << "Targets for DC '#{dc_name}' in upstream '#{upstream_name}' must be an array"
                next
              end
              
              # Check if weights add up to 100
              total_weight = targets.sum { |target| target['weight'] || 0 }
              if total_weight != 100
                @errors << "Weights for DC '#{dc_name}' in upstream '#{upstream_name}' must sum to 100, got #{total_weight}"
              end
              
              # Validate each target
              targets.each_with_index do |target, index|
                unless target['host']
                  @errors << "Target at index #{index} for DC '#{dc_name}' in upstream '#{upstream_name}' missing 'host' field"
                end
                
                unless target['weight'] && target['weight'].is_a?(Integer) && target['weight'] > 0
                  @errors << "Target at index #{index} for DC '#{dc_name}' in upstream '#{upstream_name}' must have positive integer 'weight'"
                end
              end
            end
          end
          
        rescue Psych::SyntaxError => e
          @errors << "Invalid YAML in upstreams file #{upstreams_file}: #{e.message}"
        rescue => e
          @errors << "Error validating upstreams file #{upstreams_file}: #{e.message}"
        end
      end
    end
  end
end
