require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'ledger_web/db'
require 'ledger_web/config'
require 'csv'

describe LedgerWeb::Database do
  describe "#dump_ledger_to_csv" do
    it "should not die" do
      set_config :ledger_file, fixture('small')
      file = LedgerWeb::Database.dump_ledger_to_csv
    end

    it "should dump valid csv" do
      set_config :ledger_file, fixture('small')
      file = LedgerWeb::Database.dump_ledger_to_csv

      rows = CSV.read(file.path)

      rows.should eq([
        ["1", "2012/01/01", "Transaction One", "Assets:Savings",          "$",  "100", "true", "false", "",  "$100.00"],
        ["1", "2012/01/01", "Transaction One", "Assets:Checking",         "$",  "200", "true", "false", "",  "$200.00"],
        ["1", "2012/01/01", "Transaction One", "Equity:Opening Balances", "$", "-300", "true", "false", "", "$-300.00"],
        ["6", "2012/01/02", "Lunch", "Expenses:Lunch",                    "$",   "10", "true", "false", "",   "$10.00"],
        ["6", "2012/01/02", "Lunch", "Assets:Checking",                   "$",  "-10", "true", "false", "",  "$-10.00"]
      ])
    end

    it "should dump valid csv even with quoted commodities" do
      set_config :ledger_file, fixture('quoted')
      file = LedgerWeb::Database.dump_ledger_to_csv

      rows = CSV.read(file.path)

      rows.should eq([
        ["1", "2012/01/01", "Transaction One", "Assets:Savings",          "\"Foo 123\"",  "100", "true", "false", "",  "100.00 \"Foo 123\""],
        ["1", "2012/01/01", "Transaction One", "Assets:Checking",         "\"Foo 123\"",  "200", "true", "false", "",  "200.00 \"Foo 123\""],
        ["1", "2012/01/01", "Transaction One", "Equity:Opening Balances", "\"Foo 123\"", "-300", "true", "false", "", "-300.00 \"Foo 123\""],
        ["6", "2012/01/02", "Lunch", "Expenses:Lunch",                    "\"Foo 123\"",   "10", "true", "false", "",   "10.00 \"Foo 123\""],
        ["6", "2012/01/02", "Lunch", "Assets:Checking",                   "\"Foo 123\"",  "-10", "true", "false", "",  "-10.00 \"Foo 123\""]
      ])
    end

  end

  describe "#load_database" do
    it "should load the database from a csv file" do
      set_config :ledger_file, fixture('small')
      file = LedgerWeb::Database.dump_ledger_to_csv
      count = LedgerWeb::Database.load_database(file)
      count.should eq(5)

      LedgerWeb::Database.handle[:ledger].count().should eq(5)

      convert_bd_to_string(LedgerWeb::Database.handle[:ledger].all()).should eq([
        {
          :xtn_date => Date.new(2012,1,1),
          :checknum => nil,
          :note => 'Transaction One',
          :account => 'Assets:Savings',
          :commodity => '$',
          :amount => "100.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 1,
          :cleared => true,
          :cost => "100.0"
        },
        {
          :xtn_date => Date.new(2012,1,1),
          :checknum => nil,
          :note => 'Transaction One',
          :account => 'Assets:Checking',
          :commodity => '$',
          :amount => "200.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 1,
          :cleared => true,
          :cost => "200.0"
        },
        {
          :xtn_date => Date.new(2012,1,1),
          :checknum => nil,
          :note => 'Transaction One',
          :account => 'Equity:Opening Balances',
          :commodity => '$',
          :amount => "-300.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 1,
          :cleared => true,
          :cost => "-300.0"
        },
        {
          :xtn_date => Date.new(2012,1,2),
          :checknum => nil,
          :note => 'Lunch',
          :account => 'Expenses:Lunch',
          :commodity => '$',
          :amount => "10.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 6,
          :cleared => true,
          :cost => "10.0"
        },
        {
          :xtn_date => Date.new(2012,1,2),
          :checknum => nil,
          :note => 'Lunch',
          :account => 'Assets:Checking',
          :commodity => '$',
          :amount => "-10.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 6,
          :cleared => true,
          :cost => "-10.0"
        },
      ])

    end

    it "should load the database from a csv file containing quoted things" do
      set_config :ledger_file, fixture('quoted')
      file = LedgerWeb::Database.dump_ledger_to_csv
      count = LedgerWeb::Database.load_database(file)
      count.should eq(5)

      LedgerWeb::Database.handle[:ledger].count().should eq(5)

      convert_bd_to_string(LedgerWeb::Database.handle[:ledger].all()).should eq([
        {
          :xtn_date => Date.new(2012,1,1),
          :checknum => nil,
          :note => 'Transaction One',
          :account => 'Assets:Savings',
          :commodity => '"Foo 123"',
          :amount => "100.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 1,
          :cleared => true,
          :cost => "100.0"
        },
        {
          :xtn_date => Date.new(2012,1,1),
          :checknum => nil,
          :note => 'Transaction One',
          :account => 'Assets:Checking',
          :commodity => '"Foo 123"',
          :amount => "200.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 1,
          :cleared => true,
          :cost => "200.0"
        },
        {
          :xtn_date => Date.new(2012,1,1),
          :checknum => nil,
          :note => 'Transaction One',
          :account => 'Equity:Opening Balances',
          :commodity => '"Foo 123"',
          :amount => "-300.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 1,
          :cleared => true,
          :cost => "-300.0"
        },
        {
          :xtn_date => Date.new(2012,1,2),
          :checknum => nil,
          :note => 'Lunch',
          :account => 'Expenses:Lunch',
          :commodity => '"Foo 123"',
          :amount => "10.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 6,
          :cleared => true,
          :cost => "10.0"
        },
        {
          :xtn_date => Date.new(2012,1,2),
          :checknum => nil,
          :note => 'Lunch',
          :account => 'Assets:Checking',
          :commodity => '"Foo 123"',
          :amount => "-10.0",
          :tags => '',
          :xtn_month => Date.new(2012,1,1),
          :xtn_year => Date.new(2012,1,1),
          :virtual => false,
          :xtn_id => 6,
          :cleared => true,
          :cost => "-10.0"
        },
      ])

    end
  end
end
