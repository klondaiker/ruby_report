# frozen_string_literal: true

module RubyReport
  module Generator
    class Hash < Base
      def add_report(report, **_opts)
        @report = report
      end

      def generate
        {header: report.header, rows: report.rows}
      end

      private

      attr_reader :report
    end
  end
end