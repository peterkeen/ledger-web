$:.push File.expand_path("../lib", __FILE__)

require 'ledger_web/version'

Gem::Specification.new do |s|
  s.name        = "ledger_web"
  s.version     = LedgerWeb::VERSION
  s.date        = `date +%Y-%m-%d`
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Pete Keen"]
  s.email       = ["pete@bugsplat.info"]
  s.homepage    = "https://github.com/peterkeen/ledger-web"
  s.summary     = %q{A web-based, sql-backed front-end for the Ledger command-line accounting system}
  s.description = %q{Allows arbitrary reporting on your ledger using easy-to-write SQL queries}

  s.add_dependency("pg")
  s.add_dependency("sequel")
  s.add_dependency("directory_watcher", "~> 1.5.1")
  s.add_dependency("rack", ">= 1.3.6")
  s.add_dependency("sinatra")
  s.add_dependency("sinatra-session")
  s.add_dependency("sinatra-contrib")
  s.add_dependency("rspec")
  s.add_dependency("database_cleaner")
  s.add_dependency("docverter")

  s.bindir        = 'bin'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

