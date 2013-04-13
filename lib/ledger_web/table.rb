module LedgerWeb
  class Table

    attr_reader :attributes

    def initialize(report)
      @report = report
      @decorators = []
      @attributes = {}
      yield self if block_given?
    end

    def decorate decorator
      @decorators << decorator
    end

    def clear_decorators
      @decorators.clear
    end

    def link href
      if_clause = href.delete(:if)
      href[href.keys.first] = LedgerWeb::Decorators::LinkDecorator.new(href.values.first)
      href[:if] = if_clause
      @decorators << href
    end

    def render
      body_rows = []
      header_aligns = {}

      @report.each do |row|
        body_rows << row.each_with_index.map do |cell, cell_index|
          @decorators.each do |decorator|
            dec = decorator.dup
            if_clause = dec.delete(:if)
            matcher = dec.keys.first

            next unless matcher == :all || cell.title =~ matcher
            if if_clause
              next unless if_clause.call(cell, row)
            end
            cell = dec[matcher].decorate(cell, row)
            header_aligns[cell_index] = cell.align
          end

          style = cell.style.map { |key, val| "#{key}:#{val}"}.join(";")
          %Q{<td style="#{style}"><span class="pull-#{cell.align}">#{cell.text}</span></td>}
        end.join("")
      end

      body = "<tbody>" + body_rows.map { |r| "<tr>#{r}</tr>" }.join("") + "</tbody>"
      header = "<thead><tr>" + @report.fields.each_with_index.map { |f,i| "<th><span class=\"pull-#{header_aligns[i] || 'left'}\">#{f}</span></th>" }.join("") + "</tr></thead>"

      attrs = attributes.map { |key,val| "#{key}=\"#{val}\"" }.join(" ")
      "<table #{attrs}>#{header}#{body}</table>"
    end
  end

end
