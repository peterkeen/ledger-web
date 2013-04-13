require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'ledger_web/report'
require 'ledger_web/helpers'

describe LedgerWeb::Report do
  describe "#from_query" do
    let(:helpers) { TestHelper.new }
    it "should run the query" do

      LedgerWeb::Report.session = {:from => '2012/01/01', :to => '2012/01/01'}

      load_fixture('small')

      report = LedgerWeb::Report.from_query("select count(1) as foo from ledger")
      rows = []
      report.each do |row|
        rows << row
      end

      rows[0][0].value.should eq(5)
      rows[0][0].align.should eq('left')
    end

    it "should respect defaults" do
      LedgerWeb::Report.params = {}
      helpers.default('foo', 'bar')

      report = LedgerWeb::Report.from_query("select :foo as foo")
      rows = []
      report.each do |row|
        rows << row
      end

      rows[0][0].value.should eq("bar")
    end

  end

  describe "#pivot" do
    it "should create the correct fields" do
      LedgerWeb::Report.session = {:from => '2012/01/01', :to => '2012/01/01'}
      load_fixture('small')

      report = LedgerWeb::Report.from_query("select xtn_month, account, sum(amount) from ledger group by xtn_month, account")
      report = report.pivot("account", "asc")

      report.fields.should eq([
        'xtn_month',
        'Assets:Checking',
        'Assets:Savings',
        'Equity:Opening Balances',
        'Expenses:Lunch'
      ])
      
    end

    it "should put the values in the right place" do
      LedgerWeb::Report.session = {:from => '2012/01/01', :to => '2012/01/01'}
      load_fixture('small')

      report = LedgerWeb::Report.from_query("select xtn_month, account, sum(amount)::integer from ledger group by xtn_month, account")
      report = report.pivot("account", "asc")

      report.rows[0].map(&:value).should eq(
        [Date.new(2012,1,1), 190, 100, -300, 10]
      )
    end

    it "should respect other date formats" do
      LedgerWeb::Report.session = {:from => '2012-01-01', :to => '2012-01-01'}
      load_fixture('small')

      report = LedgerWeb::Report.from_query("select xtn_month, account, sum(amount)::integer from ledger group by xtn_month, account")
      report = report.pivot("account", "asc")

      report.rows[0].map(&:value).should eq(
        [Date.new(2012,1,1), 190, 100, -300, 10]
      )
    end
  end
end
