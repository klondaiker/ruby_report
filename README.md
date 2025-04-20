# Ruby Report
A simple report generator

## Installation
Add this line to your application's `Gemfile`:

```ruby
gem "ruby_report"
gem "caxlsx" # optional: for generate xlsx
```

And then execute:

```sh
bundle install
```

## Usage

Create class
```ruby
class UserReport < RubyReport::Report
  columns :name, :age, :role, :created_at
end
```

Initialize object with data
```ruby
# data is ActiveRecords or array of objects
report = UserReport.new(data: User.all)
```

Generate report
```ruby
# Hash
report.to_h # {header: ["Name", "Age", "Role"], rows: [["Sasha", 18, "Student"]]}

# CSV
report.to_csv # IOString

# XLSX
report.to_xlsx(worksheet_name: "Worksheet") # IOString
```

## Details
Get header
```ruby
report.header # ["Name", "Age", "Role"]
```

Default translates for header get from i18n
```ruby
I18n.t("ruby_reports.#{report.class.name.snake_case}.headers.#{key}")
```

Determine custom header
```ruby
UserReport.new(data: data, header_builder: ->(key, _report) { "Custom #{key}" })
```

Get rows
```ruby
report.rows # [["Sasha", 18, "Student"], ["Jack", 30, "Worker"]]
```

Select columns
```ruby
report = UserReport.new(data: data, columns: [:name, :age])
report.headers #["Name", "Age"]
report.rows #[["Sasha", 18], ["Jack", 30]]
```

Custom row
```ruby
UserReport.new(data: data, row_resolver: ->(row) { row.user })
```

Custom row builder
```ruby
UserReport.new(data: data, row_builder: ->(_row, _key, _report) { "" })
```

Decorators
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

Formatters

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

Decorator and Formatter with scope
```ruby
class UserDecorator < RubyReport::Decorator
  def role
    I18n.t("roles.#{object.role}", account_name: scope[:account].name)
  end
end

report = UserReport.new(data: users, scope: {account: account})
```

Append/prepend other reports

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

XLSX with any worksheets
```ruby
require "ruby_report/generator/xlsx"

generator = RubyReport::Generator::Xlsx.new
generator.add_report(report, worksheet_name: "Worksheet 1")
generator.add_report(other_report, worksheet_name: "Worksheet 2")
generator.generate # IOString
```