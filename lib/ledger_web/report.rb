module LedgerWeb
  class Field

    attr_reader :title, :value_type, :span_class

    def initialize(title, value_type, span_class)
      @title = title
      @value_type = value_type
      @span_class = span_class
    end
  end

  class Value
    def initialize(val)
      @val = val
    end

    def to_s
      @val
    end
  end

  class NumericValue < Value
    def to_s
      sprintf("%0.2f", @val)
    end
  end

  class Report

    attr_accessor :error, :fields

    def self.session=(session)
      @@session = session
    end

    def self.session
      @@session
    end

    def self.params=(params)
      @@params = params
    end

    def self.params
      @@params
    end

    def self.from_query(query)
      params = {
        :from => Report.session[:from],
        :to => Report.session[:to]
      }

      @@params.each do |key, val|
        params[key.to_sym] = val
      end

      ds = DB.fetch(query, params)
      report = self.new
      begin
        row = ds.first
        if row.nil?
          raise "No data"
        end
        ds.columns.each do |col|
          value = row[col]
          if value.is_a? Numeric
            report.add_field Field.new(col.to_s, 'number', 'pull-right')
          else
            report.add_field Field.new(col.to_s, 'string', 'pull-left')
          end
        end

        ds.each do |row|
          vals = []
          ds.columns.each do |col|
            vals << row[col]
          end
          report.add_row(vals)
        end
      rescue Exception => e
        report.error = e
      end

      return report
    end

    def initialize
      @fields = []
      @rows = []
    end

    def add_field(field)
      @fields << field
    end

    def add_row(row)
      if row.length != @fields.length
        raise "row length not equal to fields length"
      end
      @rows << row
    end

    def each_row
      @rows.each do |row|
        yield row.zip(@fields)
      end
    end

    def pivot(column, sort_order)
      new_report = self.class.new

      bucket_column_index = 0
      self.fields.each_with_index do |f, i|
        if f.title == column
          bucket_column_index = i
          break
        else
          new_report.add_field(f)
        end
      end

      buckets = {}
      new_rows = {}

      self.each_row do |row|
        key = row[0, bucket_column_index].map { |r| r[0] }
        bucket_name = row[bucket_column_index][0]
        bucket_value = row[bucket_column_index + 1][0]

        if not buckets.has_key? bucket_name
          field = bucket_value.is_a?(Numeric) ? Field.new(bucket_name, 'number', 'pull-right') : Field.new(bucket_name, 'string', 'pull-left')
          buckets[bucket_name] = field
        end

        new_rows[key] ||= {}
        new_rows[key][bucket_name] = bucket_value
      end

      bucket_keys = buckets.keys.sort
      if sort_order && sort_order == 'desc'
        bucket_keys = bucket_keys.reverse
      end

      bucket_keys.each do |bucket|
        new_report.add_field(buckets[bucket])
      end

      new_rows.each do |key, value|
        row = key
        bucket_keys.each do |b|
          row << value[b]
        end

        new_report.add_row(row)
      end

      return new_report
    end
  end

end

def find_all_reports
  directories = [
    File.join(File.dirname(__FILE__), "reports"),
    File.join(ENV['HOME'], ".ledger_web", "reports")
  ]

  reports = {}

  directories.each do |dir|
    if File.directory? dir
      Dir.glob(File.join(dir, "*.erb")) do |report|
        basename = File.basename(report).gsub('.erb', '')
        reports[basename] = 1
      end
    end
  end

  reports.keys.sort.map do |report|
    name = report.split(/_/).map { |w| w.capitalize }.join(" ")
    [report, name]
  end

end
