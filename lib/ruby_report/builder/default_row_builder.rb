# frozen_string_literal: true

module RubyReport
  module Builder
    module DefaultRowBuilder
      def self.call(row, key, _report)
        row.public_send(key)
      end
    end
  end
end