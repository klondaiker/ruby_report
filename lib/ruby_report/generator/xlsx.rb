# frozen_string_literal: true

require "caxlsx"

module RubyReport
  module Generator
    class Xlsx < Base
      WORKSHEET_LETTERS_COUNT = 25
      ESCAPE_REGEXP = /["~#%&:;<>!=',@{|}\/?*()+\[\]$]/
      XLSX_XSS_SYMBOLS = %w[+ - = @ {=].freeze

      class Worksheet
        SIZES = {header_height: 40, item_height: 20}.freeze
        ALIGNMENT = {vertical: :center, horizontal: :left, wrap_text: true}.freeze
        COLORS = {tb: "0a9700", white: "ff"}.freeze

        def initialize(workbook, name)
          @workbook = workbook
          @worksheet = @workbook.add_worksheet(name: name)
          @styles = ::OpenStruct.new(
            item: @workbook.styles.add_style(alignment: ALIGNMENT),
            header: @workbook.styles.add_style(
              bg_color: COLORS.fetch(:tb),
              fg_color: COLORS.fetch(:white),
              alignment: ALIGNMENT
            )
          )
        end

        def add_header(data)
          worksheet.add_row(
            data, style: styles.header, height: SIZES.fetch(:header_height)
          )
        end

        def add_row(data)
          worksheet.add_row(
            data, style: styles.item, height: SIZES.fetch(:item_height)
          )
        end

        private

        attr_reader :workbook, :worksheet, :styles
      end

      def initialize
        @package = ::Axlsx::Package.new.tap { |package| package.use_shared_strings = true }
        @workbook = package.workbook
        @reports = []
      end

      def add_report(report, worksheet_name:)
        reports << {
          report: report,
          worksheet: Worksheet.new(workbook, sanitize_worksheet_name(worksheet_name)),
        }
      end

      def generate
        reports.each do |report|
          worksheet = report[:worksheet]
          report = report[:report]

          worksheet.add_header(report.header)

          report.each_row do |row|
            next if row.empty?

            worksheet.add_row(sanitize_row(row))
          end
        end

        package.to_stream
      end

      private

      attr_reader :package, :workbook, :reports

      def sanitize_row(row)
        row.map do |el|
          el.is_a?(String) && el.start_with?(*XLSX_XSS_SYMBOLS) ? "'#{el}" : el
        end
      end

      def sanitize_worksheet_name(name)
        truncate(name.gsub(ESCAPE_REGEXP, ""), WORKSHEET_LETTERS_COUNT)
      end

      def truncate(string, length)
        string.length > length ? string[0...length] : string
      end
    end
  end
end