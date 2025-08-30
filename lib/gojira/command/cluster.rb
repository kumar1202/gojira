require 'gojira/command/base'
require 'gojira/errors'
require 'yaml'

module Gojira
  module Command
    class Cluster < Gojira::Command::Base
      REQUIRED_CLASS_OPTIONS = %i[tls_enabled]

      desc "validate", "validates kong config for a cluster"
      method_option :kong_state_file, aliases: '-s', type: :string, desc: 'Kong State File', required: false
      method_option :env_name, aliases: '-n', type: :string, desc: 'Environment identifier name', required: false
      method_option :compliance_type, aliases: '-c', type: :string, desc: 'Compliance Type (e.g., pci, non-pci, internal, external)', required: false
      method_option :cluster_file, aliases: '-f', type: :string, desc: 'Cluster file path', required: false
      method_option :dc_name, aliases: '-d', type: :string, desc: 'DC Name', required: false
      def validate
        validate_options
        deck = Gojira::Deck::Gateway.new('deck', get_control_plane)
        deck.validate(options[:kong_state_file])
        raise Thor::Error, deck.error if deck.error.any?

        print("Kong state file validated successfully")
      end
  
      desc "diff", "diff output for kong config in a cluster"
      method_option :kong_state_file, aliases: '-s', type: :string, desc: 'Kong State File', required: false
      method_option :env_name, aliases: '-n', type: :string, desc: 'Environment identifier name', required: false
      method_option :compliance_type, aliases: '-c', type: :string, desc: 'Compliance Type (e.g., pci, non-pci, internal, external)', required: false
      method_option :cluster_file, aliases: '-f', type: :string, desc: 'Cluster file path', required: false
      method_option :dc_name, aliases: '-d', type: :string, desc: 'DC Name', required: false
      def diff
        validate_options
        deck = Gojira::Deck::Gateway.new('deck', get_control_plane)
        deck.diff(options[:kong_state_file])
        raise Thor::Error, deck.error if deck.error.any?

        print(deck.output.first)
      end

      desc "sync", "syncs kong config to a cluster"
      method_option :kong_state_file, aliases: '-s', type: :string, desc: 'Kong State File', required: false
      method_option :env_name, aliases: '-n', type: :string, desc: 'Environment identifier name', required: false
      method_option :compliance_type, aliases: '-c', type: :string, desc: 'Compliance Type (e.g., pci, non-pci, internal, external)', required: false
      method_option :cluster_file, aliases: '-f', type: :string, desc: 'Cluster file path', required: false
      method_option :dc_name, aliases: '-d', type: :string, desc: 'DC Name', required: false
      def sync
        validate_options
        deck = Gojira::Deck::Gateway.new('deck', get_control_plane)
        deck.sync(options[:kong_state_file])
        raise Thor::Error, deck.error if deck.error.any?

        print(deck.output.first)
      end

      desc "dump", "takes dump of resources from a kong cluster"
      method_option :env_name, aliases: '-n', type: :string, desc: 'Environment identifier name'
      method_option :compliance_type, aliases: '-c', type: :string, desc: 'Compliance Type'
      method_option :cluster_file, aliases: '-f', type: :string, desc: 'Cluster file path'
      method_option :dc_name, aliases: '-d', type: :string, desc: 'DC Name'
      def dump
        validate_options
        deck = Gojira::Deck::Gateway.new('deck', get_control_plane)
        deck.dump(options[:kong_state_file])
        raise Thor::Error, deck.error if deck.error.any?

        print(deck.output.first)
      end

      no_commands do
        def validate_options
          raise Thor::Error, Gojira::Errors.required_options(REQUIRED_CLASS_OPTIONS) unless REQUIRED_CLASS_OPTIONS.all? {|option| @parent_options.key? option}
          raise Thor::Error, Gojira::Errors.dc_type_invalid(dc_list) unless dc_list.include?(options['dc_name'])
        end

        def get_control_plane
          unless options[:cluster_file] && File.exist?(options[:cluster_file])
            raise Thor::Error, "Cluster file not found: #{options[:cluster_file]}"
          end

          cluster_config = YAML.load_file(options[:cluster_file])
          
          unless cluster_config[options['env_name']]
            raise Thor::Error, "Environment '#{options['env_name']}' not found in cluster file"
          end
          
          clusters = cluster_config[options['env_name']]['control_plane']
          
          unless clusters && clusters.is_a?(Array)
            raise Thor::Error, "No control plane configuration found for environment '#{options['env_name']}'"
          end

          required_cluster = clusters.select { |cluster| 
            cluster['compliance_type'] == options['compliance_type'] && 
            cluster['dc'] == options['dc_name']  
          }
          
          if required_cluster.empty?
            raise Thor::Error, "No control plane found for compliance type '#{options['compliance_type']}' and DC '#{options['dc_name']}'"
          end
          
          required_cluster.first['address']
        end

        def dc_list
          return [] unless options[:cluster_file] && File.exist?(options[:cluster_file])
          
          cluster_config = YAML.load_file(options[:cluster_file])
          return [] unless cluster_config[options['env_name']]
          
          cluster_config[options['env_name']]['dc'] || []
        end

        #TODO: Check if env_name is invalid
      end
    end
  end
end
