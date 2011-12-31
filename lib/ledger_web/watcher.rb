require 'directory_watcher'

module LedgerWeb
  class Watcher
    def self.run!
      directory = CONFIG.get :watch_directory
      glob = "*"

      if directory.nil?
        directory = File.dirname(CONFIG.get :ledger_file)
        glob = File.basename(CONFIG.get :ledger_file)
      end

      @@dw = DirectoryWatcher.new directory, :glob => glob
      @@dw.interval = CONFIG.get :watch_interval
      @@dw.stable = CONFIG.get :watch_stable_count

      @@dw.add_observer do |*args|
        args.each do |event|
          if event[0] == :stable
            puts "Loading database"
            count = load_database
            puts "Loaded #{count} records"
          end
        end
      end

      @@dw.start

    end

    def self.stop!
      @@dw.stop
    end
  end

end
