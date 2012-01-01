$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "ledger_web/version"
require 'rake'
 
task :build do
  system "gem build ledger_web.gemspec"
end
 
task :release => :build do
  system "gem push ledger_web-#{LedgerWeb::VERSION}.gem"
end
