# frozen_string_literal: true

require 'thor'
require 'gojira/command/base'
require 'gojira/command/cluster'
require 'gojira/command/env'

module Gojira
  class CLI < Thor
    check_unknown_options!

    def self.exit_on_failure?
      true
    end

    desc 'version', 'Print Gojira gem version'
    def version
      puts Gojira::VERSION
    end

    desc 'cluster', 'Commands interacting with Kong cluster'
    class_option :kong_addr, type: :string, desc: 'Kong Host & Port'
    class_option :config, type: :string, desc: 'decK config file'
    class_option :ca_cert_file, type: :string, desc: 'CA Cert File'
    class_option :tls_client_key_file, type: :string, desc: 'TLS Client Key file'
    class_option :tls_client_cert_file, type: :string, desc: 'TLS Client Cert file'
    class_option :tls_server_name, type: :string, desc: 'TLS Server Name'
    subcommand 'cluster', Gojira::Command::Cluster

    desc 'env', 'Commands interacting with Gateway env directory'
    subcommand 'env', Gojira::Command::Env
  end
end
