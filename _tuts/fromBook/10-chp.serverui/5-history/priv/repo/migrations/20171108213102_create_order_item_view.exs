#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.Repo.Migrations.CreateOrderItemView do
  use Ecto.Migration

  def up do
    execute("""
    CREATE VIEW order_items AS
      SELECT i.*, o.id as order_id
      FROM orders AS o, jsonb_to_recordset(o.items)
        AS i(name text, quantity int, price float, id text)
    """)
  end

  def down do
    execute("DROP VIEW order_items")
  end
end
