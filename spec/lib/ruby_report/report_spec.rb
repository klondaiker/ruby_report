# frozen_string_literal: true

require "spec_helper"
require "date"
require "ostruct"
require "tempfile"
require "creek"

class FakeI18n
  def self.t(key)
    key
  end
end

class DateTimeFormatter < ::RubyReport::Formatter
  def format(value)
    return value unless [::DateTime].include?(value.class)
    value.to_s
  end
end

class UserDecorator < ::RubyReport::Decorator
  def role
    r = super

    case r
    when 1
      "Student"
    when 2
      "Worker"
    else
      raise "Unknown role #{r}"
    end
  end
end

describe ::RubyReport::Report do
  let(:list) {
    [
      {name: "Sasha", age: 18, role: 1, created_at: DateTime.new(2025,2,3,4,5,6)},
      {name: "Oleg", age: 30, role: 2, created_at: DateTime.new(2024,2,3,4,5,6)}
    ]
  }

  let(:data) {
    list.map! { |d| OpenStruct.new(**d) }
  }

  let(:report_class) {
    Class.new(::RubyReport::Report) do
      columns :name, :age, :role, :created_at
    end
  }

  let(:report) {
    report_class.new(data: data)
  }

  describe ".header" do
    it "returns header" do
      expect(report.header).to eq(%w[name age role created_at])
    end

    context "with custom columns" do
      let(:report) {
        report_class.new(data: data, columns: %w[name age])
      }

      it "returns header" do
        expect(report.header).to eq(%w[name age])
      end
    end

    context "with I18n" do
      before do
        allow(report_class).to receive(:name).and_return("UserReport")
      end

      it "returns header" do
        stub_const('::I18n', FakeI18n)

        expect(report.header).to eq(
          %w[
            ruby_report.user_report.headers.name
            ruby_report.user_report.headers.age
            ruby_report.user_report.headers.role
            ruby_report.user_report.headers.created_at]
        )
      end
    end

    context "with custom header" do
      let(:report) {
        report_class.new(data: data, header_builder: ->(key, _report) { key.to_s.capitalize })
      }

      it "returns header" do
        expect(report.header).to eq(%w[Name Age Role Created_at])
      end
    end
  end

  describe ".rows" do
    it "returns rows" do
      expect(report.rows).to eq(
        [
         ["Sasha", 18, 1, DateTime.new(2025,2,3,4,5,6)],
         ["Oleg", 30, 2, DateTime.new(2024,2,3,4,5,6)]
        ]
      )
    end

    context "with custom columns" do
      let(:report) {
        report_class.new(data: data, columns: %i[name age])
      }

      it "returns rows" do
        expect(report.rows).to eq(
         [
           ["Sasha", 18],
           ["Oleg", 30]
         ]
        )
      end
    end

    context "with custom row" do
      let(:report) {
        report_class.new(data: data, row_builder: ->(row, key, _report) { row.public_send(key).to_s })
      }

      it "returns rows" do
        expect(report.rows).to eq(
          [
            %w[Sasha 18 1 2025-02-03T04:05:06+00:00],
            %w[Oleg 30 2 2024-02-03T04:05:06+00:00]
          ]
        )
      end
    end

    context "with formatter" do
      let(:report_class) {
        Class.new(::RubyReport::Report) do
          columns :name, :age, :role, :created_at, formatters: DateTimeFormatter
        end
      }

      it "returns rows" do
        expect(report.rows).to eq(
          [
            ["Sasha", 18, 1, "2025-02-03T04:05:06+00:00"],
            ["Oleg", 30, 2, "2024-02-03T04:05:06+00:00"]
          ]
        )
      end
    end

    context "with decorator" do
      let(:report_class) {
        Class.new(::RubyReport::Report) do
          columns :name, :age, :role, :created_at, decorators: UserDecorator
        end
      }
      it "returns rows" do
        expect(report.rows).to eq(
         [
           ["Sasha", 18, "Student", DateTime.new(2025,2,3,4,5,6)],
           ["Oleg", 30, "Worker", DateTime.new(2024,2,3,4,5,6)]
         ]
        )
      end
    end
  end

  describe ".to_h" do
    it "returns hash" do
      expect(report.to_h).to eq(header: report.header, rows: report.rows)
    end
  end

  describe ".to_csv" do
    it "returns csv" do
      csv = report.to_csv
      csv_data = csv.read
      csv.close

      rows = CSV.parse(csv_data)

      expect(rows).to eq [
        report.header,
        %w[Sasha 18 1 2025-02-03T04:05:06+00:00],
        %w[Oleg 30 2 2024-02-03T04:05:06+00:00]
      ]
    end
  end

  describe ".to_xlsx" do
    let(:worksheet_name) { "Report" }
    let(:report_class) {
      Class.new(::RubyReport::Report) do
        columns :name, :age, :role, :created_at, formatters: DateTimeFormatter
      end
    }

    it "returns xlsx" do
      xlsx = report.to_xlsx(worksheet_name:worksheet_name)

      tmp_file_path = File.join(Dir.tmpdir, "#{Time.now.to_i}_test.xlsx")
      file = File.open(tmp_file_path, "wb") do |f|
        f << xlsx.read
      end

      book = ::Creek::Book.new(file.path, check_file_extension: false)
      sheet = book.sheets.first
      rows = sheet.simple_rows.to_a.map(&:values)

      expect(sheet.name).to eq worksheet_name
      expect(rows).to eq(
        [
          report.header,
          ["Sasha", 18, 1, "2025-02-03T04:05:06+00:00"],
          ["Oleg", 30, 2, "2024-02-03T04:05:06+00:00"]
        ]
      )
    end
  end

  describe "add_report and prepend_report" do
    let(:other_report_class) {
      Class.new(RubyReport::Report) do
        columns :street
      end
    }

    let(:list) {
      super().each { |u| u[:street] = "Mittowa" }
    }

    let(:other_report) {
      other_report_class.new(data: data)
    }

    it "add other report" do
      report.add_report other_report

      expect(report.rows).to eq(
         [
           ["Sasha", 18, 1, DateTime.new(2025,2,3,4,5,6), "Mittowa"],
           ["Oleg", 30, 2, DateTime.new(2024,2,3,4,5,6), "Mittowa"]
         ]
       )
    end

    it "preprend other report" do
      report.prepend_report other_report

      expect(report.rows).to eq(
       [
         ["Mittowa", "Sasha", 18, 1, DateTime.new(2025,2,3,4,5,6)],
         ["Mittowa", "Oleg", 30, 2, DateTime.new(2024,2,3,4,5,6)]
       ]
     )
    end
  end
end