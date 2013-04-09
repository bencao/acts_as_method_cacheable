require 'active_support'
require 'active_record'
require 'sqlite3'
require 'pry'

db_config = YAML::load(IO.read('db/database.yml'))
db_file = db_config['development']['database']
File.delete(db_file) if File.exists?(db_file)
ActiveRecord::Base.configurations = db_config
ActiveRecord::Base.establish_connection('development')

RSpec.configure do |config|
  # == Mock Framework
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  config.mock_with :mocha
end
