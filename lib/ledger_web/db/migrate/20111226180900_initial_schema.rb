Sequel.migration do
  up do
    create_table(:ledger, :ignore_index_errors=>true) do
      Date :xtn_date
      String :checknum, :text=>true
      String :note, :text=>true
      String :account, :text=>true
      String :commodity, :text=>true
      BigDecimal :amount
      String :tags, :text=>true
      Date :xtn_month
      Date :xtn_year
      TrueClass :virtual
      Integer :xtn_id
      TrueClass :cleared
      
      index [:account]
      index [:commodity]
      index [:note]
      index [:tags]
      index [:virtual]
      index [:xtn_date]
      index [:xtn_month]
      index [:xtn_year]
    end
    
    create_table(:schema_info) do
      String :filename, :text=>true, :null=>false
      
      primary_key [:filename]
    end
  end
  
  down do
    drop_table(:ledger, :schema_info)
  end
end
    
