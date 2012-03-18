$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rspec'
require 'ledger_web/config'
require 'ledger_web/db'
require 'ledger_web/report'
require 'database_cleaner'

RSpec.configure do |config|

  config.before(:suite) do

    system 'createdb ledger-test'
    LedgerWeb::Config.should_load_user_config = false
    LedgerWeb::Config.instance.set :database_url, 'postgres://localhost/ledger-test'
    LedgerWeb::Database.connect
    LedgerWeb::Database.run_migrations
    
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    LedgerWeb::Database.close
    system 'dropdb ledger-test'
  end

end

def set_config(key, val)
  LedgerWeb::Config.instance.set key, val
end

def fixture(name)
  File.join(File.dirname(__FILE__), "fixtures", name + ".dat")
end

def convert_bd_to_string(objs)
  objs.map do |obj|
    obj.each do |k,v|
      if v.is_a? BigDecimal
        obj[k] = v.truncate(2).to_s('F')
      end
    end
    obj
  end
end

def load_fixture(name)
  set_config :ledger_file, fixture(name)
  file = LedgerWeb::Database.dump_ledger_to_csv
  LedgerWeb::Database.load_database(file)
end

def field(name, type, css_class)
  LedgerWeb::Field.new(name, type, css_class)
end

def string_field(name)
  field(name, 'string', 'pull-left')
end

def number_field(name)
  field(name, 'number', 'pull-right')
end
