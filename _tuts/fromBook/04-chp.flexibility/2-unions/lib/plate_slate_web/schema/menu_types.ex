#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.MenuTypes do
  use Absinthe.Schema.Notation

  alias PlateSlateWeb.Resolvers

  object :category do
    field :name, :string
    field :description, :string
    field :items, list_of(:menu_item) do
      resolve &Resolvers.Menu.items_for_category/3
    end
  end

  union :search_result do
    types [:menu_item, :category]
    # Almost done...
    resolve_type fn
      %PlateSlate.Menu.Item{}, _ ->
        :menu_item
      %PlateSlate.Menu.Category{}, _ ->
        :category
      _, _ ->
        nil
    end
  end

  @desc "Filtering options for the menu item list"
  input_object :menu_item_filter do

    @desc "Matching a name"
    field :name, :string

    @desc "Matching a category name"
    field :category, :string

    @desc "Matching a tag"
    field :tag, :string

    @desc "Priced above a value"
    field :priced_above, :float

    @desc "Priced below a value"
    field :priced_below, :float

    @desc "Added to the menu before this date"
    field :added_before, :date

    @desc "Added to the menu after this date"
    field :added_after, :date

  end

  object :menu_item do
    field :id, :id
    field :name, :string
    field :description, :string
    field :added_on, :date
  end

end
