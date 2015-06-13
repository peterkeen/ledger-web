require 'rubygems'
require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/session'
require 'docverter'

module LedgerWeb
  class Application < Sinatra::Base
    register Sinatra::Session

    set :session_secret, LedgerWeb::Config.instance.get(:session_secret)
    set :session_expire, LedgerWeb::Config.instance.get(:session_expire)
    set :reload_templates, true

    helpers Sinatra::Capture
    helpers LedgerWeb::Helpers

    def find_template(views, name, engine, &block)
      _views = LedgerWeb::Config.instance.get(:report_directories) + LedgerWeb::Config.instance.get(:additional_view_directories) + [File.join(File.dirname(__FILE__), 'views')]
      Array(_views).each { |v| super(v, name, engine, &block) }
    end

    before do
      if not session?
        session_start!
        today = Date.today
        session[:from] = Date.new(today.year - 1, today.month, today.day).strftime("%Y/%m/%d")
        session[:to] = today.strftime("%Y/%m/%d")
      end
      Report.session = session
      Report.params = params

      @reports = find_all_reports
    end

    post '/update-date-range' do

      if params[:reset]
        today = Date.today
        session[:from] = Date.new(today.year - 1, today.month, today.day).strftime('%Y/%m/%d')
        session[:to] = today.strftime('%Y/%m/%d')
      else
        session[:from] = Date.parse(params[:from]).strftime('%Y/%m/%d')
        session[:to] = Date.parse(params[:to]).strftime('%Y/%m/%d')
      end

      redirect back
    end

    get '/reports/:name' do
      begin
        erb params[:name].to_sym
      rescue Exception => e
        @error = e
        erb :error
      end
    end

    get '/pdf/:name' do
      begin
        res = Docverter::Conversion.run do |c|
          c.from = 'html'
          c.to = 'pdf'
          c.content = erb(params[:name].to_sym, layout: :pdf)
        end
        content_type 'application/pdf'
        return res
      rescue Exception => e
        @error = e
        erb :error
      end
    end

    get '/' do
      index_report = LedgerWeb::Config.instance.get :index_report
      if index_report
        redirect "/reports/#{index_report.to_s}"
      else
        redirect '/help'
      end
    end

    get '/help' do
      erb :help
    end
  end

end
