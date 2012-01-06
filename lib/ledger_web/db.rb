require 'sequel'
require 'sequel/extensions/migration'
require 'csv'

DB = Sequel.connect(CONFIG.get(:database_url))

Sequel::Migrator.apply(DB, File.join(File.dirname(__FILE__), "db/migrate"))

home_migrations = File.join(ENV['HOME'], '.ledger_web', 'migrate')
if File.directory?(home_migrations)
  Sequel::Migrator.run(DB, home_migrations, :table => "user_schema_changes")
end

module LedgerWeb
  class Database

    def self.load_database
      ledger_format = CONFIG.get :ledger_format
      ledger_bin_path = CONFIG.get :ledger_bin_path
      ledger_file = CONFIG.get :ledger_file
    
      # dump ledger to tempfile
      print "    dumping ledger to file...."
      file = Tempfile.new('ledger')
      system "#{ledger_bin_path} -f #{ledger_file} --format='#{ledger_format}' reg > #{file.path}"
      puts "done"
      counter = 0
      DB.transaction do
    
        CONFIG.run_hooks(:before_load, DB)
    
        print "    clearing ledger table...."
        DB["DELETE FROM ledger"].delete
        puts "done"
    
        print "    loading into database...."
        CSV.foreach(file.path) do |row|
          counter += 1
          row = Hash[*[:xtn_id, :xtn_date, :note, :account, :commodity, :amount, :cleared, :virtual, :tags, :cost].zip(row).flatten]
    
          xtn_date = Date.strptime(row[:xtn_date], '%Y/%m/%d')
    
          row[:xtn_month] = xtn_date.strftime('%Y/%m/01')
          row[:xtn_year]  = xtn_date.strftime('%Y/01/01')
          row[:cost] = row[:cost].gsub(/[^\d\.-]/, '')
    
          row = CONFIG.run_hooks(:before_insert_row, row)
          DB[:ledger].insert(row)
          CONFIG.run_hooks(:after_insert_row, row)
        end
    
        puts "    Running after_load hooks"
        CONFIG.run_hooks(:after_load, DB)
      end
      puts "    analyzing ledger table"
      DB.fetch('VACUUM ANALYZE ledger').all
      puts "done"
      counter
    end
    
    def self.load_prices
      query = <<HERE
        select
          commodity,
          min_date,
          case
            when amount = 0 then max_date
            else now()::date
          end as max_date
        from (
          select
            commodity,
            min(xtn_date) as min_date,
            max(xtn_date) as max_date,
            sum(amount) as amount
          from
            ledger
          group by
            commodity
        ) x
HERE
    
      puts "Deleting prices"
      DB["DELETE FROM prices"].delete
    
      rows = DB.fetch(query)
      proc = CONFIG.get :price_function
      skip = CONFIG.get :price_lookup_skip_symbols
    
      puts "Loading prices"
      rows.each do |row|
        if skip.include?(row[:commodity])
          next
        end
    
        prices = proc.call(row[:commodity], row[:min_date], row[:max_date])
        prices.each do |price|
          DB[:prices].insert(:commodity => row[:commodity], :price_date => price[0], :price => price[1])
        end
      end
      DB.fetch("analyze prices").all
      puts "Done loading prices"
    end
  end
end
