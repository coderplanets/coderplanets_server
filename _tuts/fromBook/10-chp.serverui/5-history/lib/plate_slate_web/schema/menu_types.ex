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

  import Absinthe.Resolution.Helpers
  alias PlateSlate.Menu
  alias PlateSlateWeb.Resolvers
  alias PlateSlateWeb.Schema.Middleware
  # Rest of file

  object :menu_item_result do
    field :menu_item, :menu_item
    field :errors, list_of(:input_error)
  end

  object :category do

    interfaces [:search_result]

    field :name, :string
    field :description, :string
    field :items, list_of(:menu_item) do
      arg :filter, :menu_item_filter
      arg :order, type: :sort_order, default_value: :asc
      resolve dataloader(Menu, :items)
    end
  end

  interface :search_result do
    field :name, :string
    resolve_type fn
      %PlateSlate.Menu.Item{}, _ ->
        :menu_item
      %PlateSlate.Menu.Category{}, _ ->
        :category
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
  # Rest of menu item object

    interfaces [:search_result]

    field :id, :id
    field :name, :string
    field :description, :string
    field :price, :decimal
    field :added_on, :date
    field :allergy_info, list_of(:allergy_info)
    field :category, :category, resolve: dataloader(Menu, :category)
    field :order_history, :order_history do
      arg :since, :date
      middleware Middleware.Authorize, "employee"
      resolve &Resolvers.Ordering.order_history/3
    end
  end

  object :order_history do
    field :orders, list_of(:order), resolve: &Resolvers.Ordering.orders/3
    field :quantity, non_null(:integer), resolve: Resolvers.Ordering.stat(:quantity)
    @desc "Gross Revenue"
    field :gross, non_null(:float), resolve: Resolvers.Ordering.stat(:gross)
  end

  object :allergy_info do
    field :allergen, :string
    field :severity, :string
  end

  input_object :menu_item_input do
    field :name, non_null(:string)
    field :description, :string
    field :price, non_null(:decimal)
    field :category_id, non_null(:id)
  end


end
