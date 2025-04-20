# frozen_string_literal: true

module RubyReport
  class Formatter < SimpleDelegator
    attr_reader :scope

    def initialize(obj, scope = {})
      super(obj)
      @scope = scope
    end

    def method_missing(method, *args, &block)
      format(super)
    end

    def respond_to_missing?(method, include_private)
      super
    end

    def format(value)
      value
    end
  end
end