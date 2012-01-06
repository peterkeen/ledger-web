Sequel.migration do
  change do
    alter_table :ledger do
      add_column :cost, BigDecimal
    end
  end
end
