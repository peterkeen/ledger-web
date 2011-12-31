require 'rubygems'
require 'sinatra/base'
require 'sinatra/session'
require 'sinatra/outputbuffer'

module LedgerWeb
  class Application < Sinatra::Base
    register Sinatra::Session
    set :session_secret, CONFIG.get(:session_secret)
    set :session_expire, CONFIG.get(:session_expire)
    set :views, CONFIG.get(:report_directories) + [File.join(File.dirname(__FILE__), 'views')]
    set :reload_templates, true

    def find_template(views, name, engine, &block)
      Array(views).each { |v| super(v, name, engine, &block) }
    end

    before do
      if not session?
        session_start!
        today = Date.today
        session[:from] = Date.new(today.year - 1, today.month, today.day)
        session[:to] = today
      end
      Report.session = session
    end

    helpers Sinatra::OutputBuffer::Helpers

    helpers do
      def partial (template, locals = {})
        erb(template, :layout => false, :locals => locals)
      end

      def table(report, options = {})
        partial(:table, :report => report)
      end

      def query(options={}, &block)
        q = erb_with_output_buffer block
        report = LedgerWeb::Report.from_query(q)
        if options[:pivot]
          report = report.pivot(options[:pivot], options[:pivot_sort_order])
        end
        return report
      end

      def erb_with_output_buffer(buf = '', block)
        @_out_buf, old_buffer = buf, @_out_buf
        block.call
        @_out_buf
      ensure
        @_out_buf = old_buffer
      end

    end

    post '/update-date-range' do

      if params[:reset]
        today = Date.today
        session[:from] = Date.new(today.year - 1, today.month, today.day).strftime('%Y/%m/%d')
        session[:to] = today.strftime('%Y/%m/%d')
      else
        session[:from] = Date.strptime(params[:from], '%Y/%m/%d').strftime('%Y/%m/%d')
        session[:to] = Date.strptime(params[:to], '%Y/%m/%d').strftime('%Y/%m/%d')
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

    get '/' do
      index_report = CONFIG.get :index_report
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
