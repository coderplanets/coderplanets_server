defmodule MastaniServerWeb.Schema.Statistics.Queries do
  @moduledoc """
  Statistics.Queries
  """
  use Helper.GqlSchemaSuite

  object :statistics_queries do
    @desc "list of user contribute in last 6 month"
    field :user_contributes, list_of(:user_contribute) do
      arg(:id, non_null(:id))

      resolve(&R.Statistics.list_contributes/3)
    end

    @desc "list cities geo info"
    field :cities_geo_info, :paged_geo_infos do
      resolve(&R.Statistics.list_cities_geo_info/3)
    end
  end
end
