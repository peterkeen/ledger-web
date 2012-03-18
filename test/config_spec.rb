require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'ledger_web/config'

describe LedgerWeb::Config do
  describe "#initialize" do

    it "should get and set simple values" do
      conf = LedgerWeb::Config.new do |config|
        config.set :key_one, "value one"
        config.set :key_two, "value two"
      end
  
      conf.get(:key_one).should eq("value one")
      conf.get(:key_two).should eq("value two")
    end

    it "should get and run simple hooks" do
      conf = LedgerWeb::Config.new do |config|
        config.add_hook :sample do |val|
          val[:foo] = val[:foo] * 2
        end
      end

      test_val = { :foo => 2 }
      conf.run_hooks(:sample, test_val)
      test_val[:foo].should eq(4)
    end
  end

  describe "#override_with" do
    it "should override keys" do
      conf_one = LedgerWeb::Config.new do |config|
        config.set :key_one, "value one"
      end

      conf_two = LedgerWeb::Config.new do |config|
        config.set :key_one, "value two"
      end

      conf_one.override_with(conf_two)

      conf_one.get(:key_one).should eq("value two")
    end

    it "should append hooks" do
      conf_one = LedgerWeb::Config.new do |config|
        config.add_hook(:sample) do |val|
          val[:list] << 'one'
        end
      end

      conf_two = LedgerWeb::Config.new do |config|
        config.add_hook(:sample) do |val|
          val[:list] << 'two'
        end
      end

      conf_one.override_with(conf_two)

      test_val = {:list => []}
      conf_one.run_hooks(:sample, test_val)
      test_val[:list].should eq(['one', 'two'])
    end
  end
end
