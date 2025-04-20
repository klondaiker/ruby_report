# frozen_string_literal: true

require "ruby_report"
require "pry"

RSpec.configure do |config|
  config.mock_with :rspec

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.order = :random
  Kernel.srand config.seed
end

