require 'directory_watcher'

module LedgerWeb
  class Watcher
    def self.run!
      directory = LedgerWeb::Config.instance.get :watch_directory
      glob = "*"

      if directory.nil?
        directory = File.dirname(LedgerWeb::Config.instance.get :ledger_file)
        glob = File.basename(LedgerWeb::Config.instance.get :ledger_file)
      end

      @@dw = DirectoryWatcher.new directory, :glob => glob
      @@dw.interval = LedgerWeb::Config.instance.get :watch_interval
      @@dw.stable = LedgerWeb::Config.instance.get :watch_stable_count

      LedgerWeb::Database.connect

      @@dw.add_observer do |*args|
        args.each do |event|
          if event.type == :stable
            puts "Loading database"
            LedgerWeb::Database.run_migrations
            file = LedgerWeb::Database.dump_ledger_to_csv
            count = LedgerWeb::Database.load_database(file)
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
