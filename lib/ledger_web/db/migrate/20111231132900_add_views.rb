Sequel.migration do
  change do
    create_or_replace_view(:accounts_days, <<HERE)
    with
        _a as (select account from ledger group by account),
        _d as (select xtn_date from ledger group by xtn_date)
    select
        account,
        xtn_date
    from
        _a cross join _d
HERE

    create_or_replace_view(:accounts_months, <<HERE)
    with
        _a as (select account from ledger group by account),
        _m as (select xtn_month from ledger group by xtn_month)
    select
        account,
        xtn_month
    from
        _a cross join _m
HERE

    create_or_replace_view(:accounts_years, <<HERE)
    with
        _a as (select account from ledger group by account),
        _y as (select xtn_year from ledger group by xtn_year)
    select
        account,
        xtn_year
    from
        _a cross join _y
HERE

  end
end
