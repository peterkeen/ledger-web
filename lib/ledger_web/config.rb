module LedgerWeb

  class Config
    attr_reader :vars, :hooks

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
        return data
      end
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

    def self.from_file(filename)
      File.open(filename) do |file|
        return eval(file.read, nil, filename)
      end
    end
  end
end

CONFIG = LedgerWeb::Config.new do |config|
  config.set :database_url,       "postgres://localhost/ledger"
  config.set :port,               "9090"
  config.set :ledger_file,        ENV['LEDGER_FILE']
  config.set :report_directories, ["#{File.dirname(__FILE__)}/reports"]
  config.set :session_secret,     'SomethingSecretThisWayPassed'
  config.set :session_expire,     60*60
  config.set :watch_interval,     5
  config.set :watch_stable_count, 3
  config.set :ledger_bin_path,    "ledger"

  config.set :ledger_format, "%(quoted(xact.beg_line)),%(quoted(date)),%(quoted(payee)),%(quoted(account)),%(quoted(commodity)),%(quoted(quantity(scrub(display_amount)))),%(quoted(cleared)),%(quoted(virtual)),%(quoted(join(note | xact.note)))\n"
  
  ledger_web_dir = "#{ENV['HOME']}/.ledger_web"

  if File.directory? ledger_web_dir
    if File.directory? "#{ledger_web_dir}/reports"
      dirs = config.get(:report_directories)
      dirs.unshift "#{ledger_web_dir}/reports"
      config.set :report_directories, dirs
    end
    
    if File.exists? "#{ledger_web_dir}/config.rb"
      config.override_with(LedgerWeb::Config.from_file("#{ledger_web_dir}/config.rb"))
    end
  end
end
