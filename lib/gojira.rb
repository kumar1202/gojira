# frozen_string_literal: true

require 'thor'
require_relative 'gojira/version'
require_relative 'gojira/deck/base'
require_relative 'gojira/deck/gateway'
require_relative 'gojira/deck/file'
require_relative 'gojira/cli'

module Gojira
  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end

    def configure
      yield(config)
    end

    def reset!
      @config = nil
    end
  end
end
