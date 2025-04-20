# frozen_string_literal: true

module RubyReport
  class Decorator < SimpleDelegator
    attr_reader :scope

    def initialize(obj, scope = {})
      super(obj)
      @scope = scope
    end
  end
end