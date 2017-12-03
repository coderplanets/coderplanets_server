#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlate.Repo.Migrations.CreateMenuTagTaggings do
  use Ecto.Migration

  def change do
    create table(:items_taggings, primary_key: false) do
      add :item_id, references(:items), null: false
      add :item_tag_id, references(:item_tags), null: false
    end
  end
end
