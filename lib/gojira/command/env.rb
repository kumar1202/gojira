# frozen_string_literal: true

require 'gojira/command/base'
require 'gojira/apiops/validations'
require 'gojira/apiops/merge'
require 'gojira/errors'

module Gojira
  module Command
    class Env < Gojira::Command::Base
      desc 'lint', 'lints env repo and validates against conventions'
      method_option :gateway_folder, aliases: '-f', type: :string, desc: 'Gateway configs folder path'
      method_option :env_name, aliases: '-n', type: :string, desc: 'Environment identifier name'
      method_option :cluster_file, aliases: '-c', type: :string, desc: 'Path to cluster definition file'
      def lint
        validation_engine = APIOps::Validations.new(options[:gateway_folder], options[:env_name], options[:cluster_file])
        validation_engine.execute

        raise Thor::Error, Gojira::Errors.lint_failed(validation_engine.errors) if validation_engine.errors.any?
        print("Env successfully validated")
      end

      desc 'generate', 'generates kong state for the env repo'
      method_option :gateway_folder, aliases: '-f', type: :string, desc: 'Gateway configs folder path'
      method_option :env_name, aliases: '-n', type: :string, desc: 'Environment identifier name'
      method_option :cluster_file, aliases: '-f', type: :string, desc: 'Path to Cluster definition file'
      method_option :compliance_type, aliases: '-c', type: :string, desc: 'Compliance Type(pci/non-pci)'
      method_option :dc_name, aliases: '-d', type: :string, desc: 'DC Name'
      def generate
        merge_engine = APIOps::Merge.new()
        merge_engine.execute

        raise Thor::Error, Gojira::Errors.merge_failed(merge_engine.errors) if merge_engine.errors.any?
        print("Merge config validated at")
      end
    end
  end
end
