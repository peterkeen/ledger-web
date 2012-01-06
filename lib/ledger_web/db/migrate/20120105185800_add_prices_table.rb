Sequel.migration do
  change do
    create_table(:prices) do
      Date :price_date
      String :commodity, :text => true
      BigDecimal :price

      index [:price_date]
      index [:commodity]
      index [:price_date, :commodity]
    end
  end
end
