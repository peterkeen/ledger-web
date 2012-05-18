Ledger Web
----------

Ledger Web is a web-based, postgresql-backed reporting system for the [Ledger](http://www.ledger-cli.org) command-line accounting system.
It is intended to be completely flexible, allowing you to write whatever reports you want. Note that Ledger Web requires **PostgreSQL version 9.0 or greater**.

To install:

    $ gem install ledger_web
    $ createdb ledger
    
To run:

    $ ledger_web
    
From there, open up http://localhost:9090 in your browser and poke around. You'll see a few example reports.

#### Configuration

Configuring Ledger Web is pretty simple. Create a file at `~/.ledger_web/config.rb` that looks something like this:


    LedgerWeb::Config.new do |config|
      config.set :database_url, "postgres://localhost/ledger"
    end

`:database_url` should point at your database instance. It doesn't have to be local, but the configured user needs to be able to alter the schema. There are a bunch more settings that you can set:

* `:index_report` is the report that Ledger Web will redirect your browser to when you open it up the first time. Defaults to `:help`
* `:port` is the port that Ledger Web will run on. Defaults to `9090`
* `:ledger_file` is the file that Ledger Web will read. Defaults to the `LEDGER_FILE` environment variable
* `:ledger_bin_path` is the path to the ledger binary. Defaults to finding it in the `PATH`

#### Writing Reports

Reports are just HTML ERB files that live in `~/.ledger_web/reports`. Ledger Web provides a few useful helpers that let you easily define SQL queries. Here's an example report:

    <% @query = query do %>
    select
        xtn_month,
        account,
        sum(amount)
    from
        ledger
    where
        (account ~ 'Income'
        or account ~ 'Expenses')
        and xtn_date between :from and :to
    group by
        xtn_month,
        account
    <% end %>
    <%= table @query %>

The `query` helper takes a block of SQL and returns a `LedgerWeb::Report` instance. It can take a few options:

* `:pivot` is the name of a column to pivot the report on. 
* `:pivot_sort_order` says how to order the resulting pivoted columns. Can be `asc` or `desc`. Defaults to `asc`.

Ledger Web uses [Twitter Bootstrap](http://twitter.github.com/bootstrap) for formatting, so you can use whatever you want to format your reports from there. 

The `table` helper takes a query produced by the `query` helper and some options and builds an HTML table. Also, it can take a `:links` option which will linkify values in the table. Here's an example:

    :links => {"Account" => "/reports/register?account=:1"}
    
This says that every value in the `Account` column will be surrounded with an `<a>` tag pointing at `/reports/register?account=:1`, where `:1` will be replaced by the value in column 1 of that particular row. You can also use `:title` in a link template. It will get replaced with the title of the column that is currently getting linked. In this case, `:title` would get replaced with `Account`. 

#### Customizing

You can put [Sequel migrations](http://sequel.rubyforge.org/rdoc/files/doc/migration_rdoc.html) in `~/.ledger_web/migrate` and they'll get applied as necessary at startup.

#### Hooks

Ledger Web provides several different hooks that get run during the data load process. 

* `:before_insert_row` gets the Sequel database and the current row immediatley before insertion. Row is to be modified in place.
* `:after_insert_row` gets the Sequel database and the current row. Row modifications don't matter.
* `:before_load` gets the Sequel database
* `:after_load` gets the Sequel database

To define a hook, put something like this in your config file:

    config.add_hook :before_insert_row do |db, row|
      # modify the row in place
    end
    
#### Schema

The base table is named `ledger`. Here's the DDL:

    create table ledger (
        xtn_id integer,  -- line number of the first line of the transaction
        xtn_date date,   -- date of the transaction
        xtn_month date,  -- month pre-extracted from the date
        xtn_year date,   -- year pre-extracted from the date
        checknum text,   -- check number (code)
        note text,       -- payee
        account text,    -- account name
        commodity text,  -- commodity
        amount number,   -- amount
        tags text,       -- any tags attached to the transaction
        virtual boolean, -- if the transaction is virutal or not
        cleared boolean  -- if the transaction is cleared or not
    )

In addition, there's a few predefined views:

    create view accounts_months as
    with
        _a as (select account from ledger group by account),
        _m as (select xtn_month from ledger group by xtn_month)
    select
        account,
        xtn_month
    from
        _a cross join _m
    ;
    
    create view accounts_days as
    with
        _a as (select account from ledger group by account),
        _d as (select xtn_date from ledger group by xtn_date)
    select
        account,
        xtn_date
    from
        _a cross join _d
    ;
    
    create view accounts_years as
    with
        _a as (select account from ledger group by account),
        _y as (select xtn_year from ledger group by xtn_year)
    select
        account,
        xtn_year
    from
        _a cross join _y
    ;
    
