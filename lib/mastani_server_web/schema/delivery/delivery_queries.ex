defmodule MastaniServerWeb.Schema.Delivery.Queries do
  @moduledoc """
  Delivery.Queries
  """
  use Helper.GqlSchemaSuite

  object :delivery_queries do
    @desc "get mention list?"
    field :xxxx_todo, :boolean do
      arg(:id, non_null(:id))

      resolve(&R.Delivery.mention_others/3)
    end
  end
end
