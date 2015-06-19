module LedgerWeb

  class Config
    attr_reader :vars, :hooks

    @@should_load_user_config = true
    @@instance = nil

    def self.should_load_user_config
      @@should_load_user_config
    end

    def self.should_load_user_config=(val)
      @@should_load_user_config = val
    end

    def initialize
      @vars = {}
      @hooks = {}

      if block_given?
        yield self
      end
    end

    def set(key, value)
      @vars[key] = value
    end

    def get(key)
      @vars[key]
    end

    def add_hook(phase, &block)
      _add_hook(phase, block)
    end

    def _add_hook(phase, hook)
      @hooks[phase] ||= []
      @hooks[phase] << hook
    end

    def run_hooks(phase, data)
      if @hooks.has_key? phase
        @hooks[phase].each do |hook|
          hook.call(data)
        end
      end
      return data
    end

    def override_with(config)
      config.vars.each do |key, value|
        set key, value
      end

      config.hooks.each do |phase, hooks|
        hooks.each do |hook|
          _add_hook phase, hook
        end
      end
    end

    def load_user_config(user_dir)
      if LedgerWeb::Config.should_load_user_config && File.directory?(user_dir)
        if File.directory? "#{user_dir}/reports"
          dirs = self.get(:report_directories)
          dirs.unshift "#{user_dir}/reports"
          self.set :report_directories, dirs
        end

        if File.directory? "#{user_dir}/migrate"
          self.set :user_migrate_dir, "#{user_dir}/migrate"
        end

        if File.exists? "#{user_dir}/config.rb"
          self.override_with(LedgerWeb::Config.from_file("#{user_dir}/config.rb"))
        end
      end
    end

    def self.from_file(filename)
      File.open(filename) do |file|
        return eval(file.read, nil, filename)
      end
    end

    def self.instance
      @@instance ||= LedgerWeb::Config.new do |config|
        config.set :database_url,       "postgres://localhost/ledger"
        config.set :port,               "9090"
        config.set :ledger_file,        ENV['LEDGER_FILE']
        config.set :report_directories, ["#{File.dirname(__FILE__)}/reports"]
        config.set :additional_view_directories, []
        config.set :session_secret,     'SomethingSecretThisWayPassed'
        config.set :session_expire,     60*60
        config.set :watch_interval,     5
        config.set :watch_stable_count, 3
        config.set :ledger_bin_path,    "ledger"

        config.set :ledger_format, "%(quoted(xact.beg_line)),%(quoted(date)),%(quoted(payee)),%(quoted(account)),%(quoted(commodity)),%(quoted(quantity(scrub(display_amount)))),%(quoted(cleared)),%(quoted(virtual)),%(quoted(join(note | xact.note))),%(quoted(cost))\n"
        config.set :ledger_columns, [ :xtn_id, :xtn_date, :note, :account, :commodity, :amount, :cleared, :virtual, :tags, :cost ]

        config.set :price_lookup_skip_symbols, ['$']

        func = Proc.new do |symbol, min_date, max_date|
          LedgerWeb::YahooPriceLookup.new(symbol, min_date - 1, max_date).lookup
        end
        config.set :price_function, func
      end
    end
  end
end
