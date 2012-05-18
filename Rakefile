$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "ledger_web/version"
require 'rake'
 
task :build => :test do
  system "gem build ledger_web.gemspec"
end
 
task :release => :build do
  system "gem push ledger_web-#{LedgerWeb::VERSION}.gem"
end

task :test do
  system 'rspec --color --format=documentation test'
end

task :install => :build do
  system "gem install ledger_web-#{LedgerWeb::VERSION}.gem"
end