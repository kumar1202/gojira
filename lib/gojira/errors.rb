# frozen_string_literal: true

require 'thor'

module Gojira
  class Errors
    class << self
      def required_options(required_options_list)
        "Pass all the required options as arguments #{required_options_list}"
      end

      def lint_failed(lint_output)
        "Lint process failed, the env directory is not correctly formatted.\nCorrect these errors:\n#{lint_output}"
      end

      def merge_failed(merge_output)
        "Merge process failed, the env directory is not correctly formatted. Run lint stage again!\nErrors:\n#{merge_output}"
      end

      def dc_type_invalid(dc_list)
        "The passed dc_name is not a valid DC name in this environment. Please pass a DC name from this list: #{dc_list}"
      end
    end
  end
end
