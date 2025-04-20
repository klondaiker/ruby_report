# frozen_string_literal: true

module RubyReport
  class Report
    class << self
      attr_reader :columns_set, :decorators, :formatters

      def columns(*keys, decorators: ::RubyReport::Decorator, formatters: ::RubyReport::Formatter)
        @columns_set = Set.new(keys)
        @decorators = decorators
        @formatters = formatters
      end
    end

    def initialize(
      data:, scope: nil, columns: nil,
      header_builder: ::RubyReport::Builder::DefaultHeaderBuilder,
      row_builder: ::RubyReport::Builder::DefaultRowBuilder,
      row_resolver: ->(row) { row }
    )
      @data = data
      @scope = scope
      @columns =
        if columns.nil?
          self.class.columns_set || raise("Columns not defined")
        else
          Set.new(columns)
        end
      @header_builder = header_builder
      @row_builder = row_builder
      @row_resolver = row_resolver
      @reports = [self]
    end

    def add_report(report)
      reports << report
    end

    def prepend_report(report)
      reports.unshift(report)
    end

    def header
      @header ||= reports.flat_map do |report|
        if report == self
          report.build_header
        else
          report.header
        end
      end
    end

    def rows
      @rows ||= each_row.to_a
    end

    def each_row
      return enum_for(:each_row) unless block_given?

      method =
        if data.respond_to?(:find_each)
          :find_each
        else
          :each
        end

      data.public_send(method) do |row|
        yield collect_row(row)
      end
    end

    def to_with(generator, **opts)
      report = generator.new
      report.add_report(self, **opts)
      report.generate
    end

    [:hash, :csv, :xlsx].each do |type|
      define_method("to_#{type}") do |**opts|
        require "ruby_report/generator/#{type}"

        to_with(
          Object.const_get("::RubyReport::Generator::#{type.to_s.capitalize}"),
          **opts
        )
      end
    end

    alias_method :to_h, :to_hash

    def build_header
      columns.map do |key|
        header_builder.call(key, self)
      end
    end

    def build_row(row)
      current_row = row_resolver.call(row)

      return [] unless current_row

      Array(decorators).each { |decorator| current_row = decorator.new(current_row, scope) }
      Array(formatters).each { |formatter| current_row = formatter.new(current_row, scope) }

      columns.map do |key|
        row_builder.call(current_row, key, self)
      end
    end

    def collect_row(row)
      result_row = []

      reports.each do |report|
        result_row +=
          if report == self
            report.build_row(row)
          else
            report.collect_row(row)
          end
      end

      result_row
    end

    private

    attr_reader :data, :scope, :columns, :header_builder, :row_builder, :row_resolver, :reports

    def decorators
      self.class.decorators
    end

    def formatters
      self.class.formatters
    end
  end
end