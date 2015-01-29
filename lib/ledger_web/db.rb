require 'sequel'
require 'sequel/extensions/migration'
require 'csv'
require 'tempfile'

module LedgerWeb
  class Database

    def self.connect
      @@db = Sequel.connect(LedgerWeb::Config.instance.get(:database_url))
      self.run_migrations()
    end

    def self.close
      @@db.disconnect
    end

    def self.handle
      @@db
    end

    def self.run_migrations
      Sequel::Migrator.apply(@@db, File.join(File.dirname(__FILE__), "db/migrate"))

      user_migrations = LedgerWeb::Config.instance.get :user_migrate_dir
      if not user_migrations.nil?
        Sequel::Migrator.run(@@db, user_migrations, :table => "user_schema_changes")
      end
    end

    def self.dump_ledger_to_csv
      ledger_bin_path = LedgerWeb::Config.instance.get :ledger_bin_path
      ledger_file = LedgerWeb::Config.instance.get :ledger_file
      ledger_format = LedgerWeb::Config.instance.get :ledger_format

      puts "Dumping ledger to file..."
      file = Tempfile.new('ledger')
      system "#{ledger_bin_path} -f #{ledger_file} --format='#{ledger_format}' reg > #{file.path}"
      replaced_file = Tempfile.new('ledger')
      replaced_file.write(file.read.gsub('\"', '""'))
      replaced_file.flush

      puts "Dump finished"
      return replaced_file
    end
      
    def self.load_database(file)
      counter = 0
      @@db.transaction do
    
        LedgerWeb::Config.instance.run_hooks(:before_load, @@db)

        puts "Clearing ledger table...."
        @@db["DELETE FROM ledger"].delete
        puts "Done clearing ledger table"
    
        puts "Loading into database...."

        ledger_columns = LedgerWeb::Config.instance.get :ledger_columns

        CSV.foreach(file.path) do |row|
          counter += 1
          row = Hash[*ledger_columns.zip(row).flatten]

          xtn_date = Date.strptime(row[:xtn_date], '%Y/%m/%d')
    
          row[:xtn_month] = xtn_date.strftime('%Y/%m/01')
          row[:xtn_year]  = xtn_date.strftime('%Y/01/01')
          row[:cost] = parse_cost(row[:cost])
    
          row = LedgerWeb::Config.instance.run_hooks(:before_insert_row, row)
          @@db[:ledger].insert(row)
          LedgerWeb::Config.instance.run_hooks(:after_insert_row, row)
        end
    
        puts "Running after_load hooks"
        LedgerWeb::Config.instance.run_hooks(:after_load, @@db)
      end
      puts "Analyzing ledger table"
      @@db.fetch('VACUUM ANALYZE ledger').all
      puts "Done!"
      counter
    end

    def self.parse_cost(cost)
      match = cost.match(/([\d\.-]+) (.+) {(.+)} \[(.+)\]/)
      if match
        amount = match[1].to_f
        price = match[3].gsub(/[^\d\.-]/, '').to_f
        return price * amount
      end
      cost.gsub(/[^\d\.-]/, '')
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
    
      puts "    Deleting prices"
      @@db["DELETE FROM prices"].delete
    
      rows = @@db.fetch(query)
      proc = LedgerWeb::Config.instance.get :price_function
      skip = LedgerWeb::Config.instance.get :price_lookup_skip_symbols
    
      puts "Loading prices"
      rows.each do |row|
        if skip.include?(row[:commodity])
          next
        end
    
        prices = proc.call(row[:commodity], row[:min_date], row[:max_date])
        prices.each do |price|
          @@db[:prices].insert(:commodity => row[:commodity], :price_date => price[0], :price => price[1])
        end
      end
      @@db.fetch("analyze prices").all
      puts "Done loading prices"
    end
  end
end

