module LedgerWeb
  class Field
    def initialize(value)
      @value = value
    end

    def to_s
      return @value
    end

    def span_class
      'pull-left'
    end
  end

  class NumericField < Field
    def to_s
      return sprintf("%0.2f", @value)
    end

    def span_class
      'pull-right'
    end
  end

  class ReportRow
    def initialize(row)
      @row = row
    end

    def [](field)
      value = @row[field]
      if value.instance_of? BigDecimal
        return NumericField.new(value)
      else
        return Field.new(value)
      end
    end
  end

  class Report

    attr_reader :error

    def self.session=(session)
      @@session = session
    end

    def self.session
      @@session
    end

    def self.from_query


    def initialize(query, options={})
      @query = DB.fetch(query, :from => Report.session[:from], :to => Report.session[:to])
    end

    def headers
      return @headers if @headers

      begin
        headers = []
        row = @query.first
        if row.nil?
          raise "No data"
        end
        @query.columns.each do |col|
          value = row[col]
          if value.instance_of? BigDecimal
            headers << [col, 'pull-right', 'number']
          else
            headers << [col, 'pull-left', 'string']
          end
        end
        @headers = headers
        return headers
      rescue Exception => e
        @error = e
        return []
      end
    end

    def axis(col)
      return @axis[col] if @axis

      row = @query.first
      axis = {}

      columns = @query.columns[1,@query.columns.length]
      groups = {}
      columns.each do |col|
        if ! row[col].instance_of? BigDecimal
          return 0
        end
        oom = Math.log10(row[col].to_f.abs)
        groups[oom] ||= []
        groups[oom] << col
      end

      keys = groups.keys.sort.reverse
      partition_point = (keys.length / 2.0).floor

      keys.each_with_index do |key,i|
        groups[key].each_with_index do |c|
          if i <= partition_point
            axis[c] = 0
          else
            axis[c] = 1
          end
        end
      end
      @axis = axis
      return axis[col]
    end

    def rows
      if @error
        return
      end

      @query.each do |row|
        yield ReportRow.new(row)
      end
    end
  end
end
