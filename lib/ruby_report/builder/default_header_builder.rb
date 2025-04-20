# frozen_string_literal: true

module RubyReport
  module Builder
    module DefaultHeaderBuilder
      def self.call(key, report)
        if defined?(::I18n)
          ::I18n.t("ruby_report.#{underscore(report.class.name.to_s)}.headers.#{key}")
        else
          key.to_s
        end
      end

      private

      def self.underscore(name)
        word = name.gsub("::", "/")
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.downcase!
        word
      end
    end
  end
end