require 'active_support'
require 'active_record'
require 'sqlite3'
require 'pry'

ActiveRecord::Base.configurations = YAML::load(IO.read('db/database.yml'))
ActiveRecord::Base.establish_connection('development')

RSpec.configure do |config|
  # == Mock Framework
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  config.mock_with :mocha
end
