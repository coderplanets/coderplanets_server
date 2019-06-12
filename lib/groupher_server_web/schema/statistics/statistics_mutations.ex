defmodule GroupherServerWeb.Schema.Statistics.Mutations do
  @moduledoc """
  Statistics mutations
  """
  use Helper.GqlSchemaSuite

  object :statistics_mutations do
    field :make_contrubute, :user_contribute do
      arg(:user_id, non_null(:id))

      resolve(&R.Statistics.make_contrubute/3)
    end
  end
end
