# frozen_string_literal: true

module Gojira
  module Command
    class Base < Thor
      def self.banner(command, _namespace = nil, _subcommand = false)
        "#{basename} #{subcommand_prefix} #{command.usage}"
      end

      def self.subcommand_prefix
        name.split('::').last.gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2').gsub(/([a-z\d])([A-Z])/, '\1-\2').downcase
      end
    end
  end
end
