#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.Repo.Migrations.AddRelationsToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :customer_id, references(:users)
      add :readied_by_id, references(:users)
    end
  end
end
