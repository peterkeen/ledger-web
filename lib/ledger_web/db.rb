require 'sequel'
require 'sequel/extensions/migration'
require 'csv'

DB = Sequel.connect(CONFIG.get :database_url)

Sequel::Migrator.apply(DB, File.join(File.dirname(__FILE__), "db/migrate"))

home_migrations = File.join(ENV['HOME'], '.ledger_web', 'migrate')
if File.directory?(home_migrations)
  Sequel::Migrator.run(DB, home_migrations, :table => "user_schema_changes")
end


def load_database
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
      row = Hash[*[:xtn_id, :xtn_date, :note, :account, :commodity, :amount, :cleared, :virtual, :tags].zip(row).flatten]

      xtn_date = Date.strptime(row[:xtn_date], '%Y/%m/%d')

      row[:xtn_month] = xtn_date.strftime('%Y/%m/01')
      row[:xtn_year]  = xtn_date.strftime('%Y/01/01')

      row = CONFIG.run_hooks(:before_insert_row, row)
      DB[:ledger].insert(row)
      CONFIG.run_hooks(:after_insert_row, row)
    end

    CONFIG.run_hooks(:after_load, DB)
  end
  print "    analyzing ledger table"
  DB.fetch('VACUUM ANALYZE ledger')
  puts "done"
  counter
end
