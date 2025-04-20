# frozen_string_literal: true

module RubyReport
  module Generator
    class Base
      def add_report(report, **opts)
        raise NotImplementedError
      end

      def generate
        raise NotImplementedErro
      end
    end
  end
end