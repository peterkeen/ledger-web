require 'rack/utils'
require 'time'
require 'cgi'

module LedgerWeb
  module Helpers

    include Rack::Utils

    def partial (template, locals = {})
      erb(template, :layout => false, :locals => locals)
    end

    def table(report, options = {})
      Table.new(report) do |t|
        t.decorate :all => LedgerWeb::Decorators::NumberDecorator.new
        t.attributes[:class] = 'table table-striped table-hover table-bordered table-condensed'
        yield t if block_given?
      end.render
    end

    def query(options={}, &block)
      q = capture(&block)
      report = Report.from_query(q)
      if options[:pivot]
        report = report.pivot(options[:pivot], options[:pivot_sort_order])
      end
      return report
    end

    def expect(expected)
      not_present = []
      expected.each do |key|
        if not params.has_key? key
          not_present << key
        end
      end

      if not_present.length > 0
        raise "Missing params: #{not_present.join(', ')}"
      end
    end

    def default(key, value)
      if not Report.params.has_key? key
        puts "Setting #{key} to #{value}"
        Report.params[key] = value
      end
    end

    def relative_time(start_time)
      diff_seconds = Time.now.utc - start_time.utc
      case diff_seconds
      when 0 .. 59
        return"#{diff_seconds.to_i} seconds ago"
      when 60 .. (3600-1)
        return "#{(diff_seconds/60).to_i} minutes ago"
      when 3600 .. (3600*24-1)
        return "#{(diff_seconds/3600).to_i} hours ago"
      when (3600*24) .. (3600*24*30)
        return "#{(diff_seconds/(3600*24)).to_i} days ago"
      else
        return start_time.strftime("%m/%d/%Y")
      end
    end

    def visualization(report, options={}, &block)
      vis = capture(&block)
      @vis_count ||= 0
      @vis_count += 1
      @_out_buf.concat(
        partial(
          :visualization,
          :report => report,
          :visualization_code => vis,
          :div_id => "vis_#{@vis_count}"
        )
      )
    end
  end
end
