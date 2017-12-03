#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :name, :string, null: false
      add :description, :string
      add :price, :decimal, null: false
      add :added_on, :date, null: false, default: fragment("NOW()")
      add :category_id, references(:categories, on_delete: :nothing)

      timestamps()
    end

    create index(:items, [:category_id])
  end
end
