# frozen_string_literal: true

require "csv"

module RubyReport
  module Generator
    class Csv < Base
      def add_report(report, **_opts)
        @report = report
      end

      def generate
        temp_file = ::Tempfile.new

        ::CSV.open(temp_file.path, "wb") do |csv|
          csv << report.header

          report.each_row do |row|
            csv << row
          end
        end

        temp_file
      end

      private

      attr_reader :report
    end
  end
end