libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'ledger_web/config'
require 'ledger_web/db'
require 'ledger_web/report'
require 'ledger_web/watcher'
require 'ledger_web/app'


ledger_web_dir = "#{ENV['HOME']}/.ledger_web"

if File.directory? ledger_web_dir
  if File.directory? File.join(ledger_web_dir, "lib")
    Dir.glob(File.join(ledger_web_dir, "lib", "*.rb")).each do |f|
      require f
    end
  end
end
