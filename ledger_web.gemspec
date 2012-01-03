$:.push File.expand_path("../lib", __FILE__)

require 'ledger_web/version'

Gem::Specification.new do |s|
  s.name        = "ledger_web"
  s.version     = LedgerWeb::VERSION
  s.date        = "2011-12-31"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Pete Keen"]
  s.email       = ["pete@bugsplat.info"]
  s.homepage    = "https://github.com/peterkeen/ledger-web"
  s.summary     = %q{A web-based, sql-backed front-end for the Ledger command-line accounting system}
  s.description = %q{Allows arbitrary reporting on your ledger using easy-to-write SQL queries}

  s.add_dependency("pg")
  s.add_dependency("sequel")
  s.add_dependency("directory_watcher")
  s.add_dependency("sinatra")
  s.add_dependency("sinatra-session")
  s.add_dependency("sinatra-contrib")

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

