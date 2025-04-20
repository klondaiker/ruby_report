# Ruby Report

Ruby Report is a simple and flexible tool for generating reports in various formats (Hash, CSV, XLSX). The library supports custom headers, data formatting, decorators, and the ability to combine multiple reports.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Key Features](#key-features)
  - [Report Generation](#report-generation)
  - [Customizing Headers](#customizing-headers)
  - [Selecting Columns](#selecting-columns)
  - [Customizing Rows](#customizing-rows)
  - [Decorators](#decorators)
  - [Formatters](#formatters)
  - [Scope](#scope)
  - [Combining Reports](#combining-reports)
  - [Generating XLSX with Multiple Sheets](#generating-xlsx-with-multiple-sheets)

## Installation

Add the following lines to your application's `Gemfile`:

```ruby
gem "ruby_report"
gem "caxlsx" # optional: for generating XLSX files
```

Then run:

```sh
bundle install
```

---

## Quick Start

1. Create a report class by inheriting from `RubyReport::Report`:

```ruby
class UserReport < RubyReport::Report
  columns :name, :age, :role, :created_at
end
```

2. Initialize the report object with data (ActiveRecord or an array of objects):

```ruby
report = UserReport.new(data: User.all)
```

3. Generate the report in the desired format:

```ruby
# Hash
report.to_h 
# => {header: ["Name", "Age", "Role"], rows: [["Sasha", 18, "Student"]]}

# CSV
report.to_csv 
# => IOString

# XLSX
report.to_xlsx(worksheet_name: "Worksheet") 
# => IOString
```

---

## Features

### Report Generation

Ruby Report supports multiple output formats:

- **Hash**: Returns a structure with headers and rows.
- **CSV**: Generates a CSV file.
- **XLSX**: Creates an Excel file.

```ruby
report.to_h
report.to_csv
report.to_xlsx(worksheet_name: "My Worksheet")
```

---

### Customizing Headers

Headers are fetched from I18n by default:

```ruby
I18n.t("ruby_reports.user_report.headers.name") # => "Name"
```

You can override headers using a custom builder:

```ruby
UserReport.new(
  data: data,
  header_builder: ->(key, _report) { "Custom #{key}" }
)
```

---

### Selecting Columns

Select only the necessary columns:

```ruby
report = UserReport.new(data: data, columns: [:name, :age])
report.headers # => ["Name", "Age"]
report.rows    # => [["Sasha", 18], ["Jack", 30]]
```

---

### Customizing Rows

Use `row_resolver` to modify row data:

```ruby
UserReport.new(
  data: data,
  row_resolver: ->(row) { row.user }
)
```

Or use `row_builder` for full customization:

```ruby
UserReport.new(
  data: data,
  row_builder: ->(_row, key, _report) { key.upcase }
)
```

---

### Decorators

Decorators allow you to modify data before output:

```ruby
class UserDecorator < RubyReport::Decorator
  def role
    I18n.t("roles.#{object.role}")
  end
end

class UserReport < RubyReport::Report
  columns :name, :age, :role, decorators: [UserDecorator]
end
```

---

### Formatters

Formatters transform values into the desired format:

```ruby
class TimeFormatter < RubyReport::Formatter
  def format(value)
    return value unless [::Time, ActiveSupport::TimeWithZone].include?(value.class)
    value.utc.to_formatted_s(:report)
  end
end

class UserReport < RubyReport::Report
  columns :name, :age, :role, :created_at, formatters: [TimeFormatter]
end
```

---

### Scope

Pass additional data through `scope`:

```ruby
class UserDecorator < RubyReport::Decorator
  def role
    I18n.t("roles.#{object.role}", account_name: scope[:account].name)
  end
end

report = UserReport.new(data: users, scope: { account: account })
```

---

### Combining Reports

Combine multiple reports into one:

```ruby
class AccountReport < RubyReport::Report
  columns :name
end

class AddressReport < RubyReport::Report
  columns :street
end

user_report.prepend_report(account_report)
user_report.add_report(address_report)
```

---

### Generating XLSX with Multiple Sheets

Create an XLSX file with multiple sheets:

```ruby
require "ruby_report/generator/xlsx"

generator = RubyReport::Generator::Xlsx.new
generator.add_report(report, worksheet_name: "Worksheet 1")
generator.add_report(other_report, worksheet_name: "Worksheet 2")
generator.generate # => IOString
```

