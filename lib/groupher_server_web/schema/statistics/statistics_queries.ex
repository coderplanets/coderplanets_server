defmodule GroupherServerWeb.Schema.Statistics.Queries do
  @moduledoc """
  Statistics.Queries
  """
  use Helper.GqlSchemaSuite

  object :statistics_queries do
    @desc "list cities geo info"
    field :cities_geo_info, :paged_geo_infos do
      resolve(&R.Statistics.list_cities_geo_info/3)
    end

    @desc "basic online status"
    field :online_status, :online_status_info do
      arg(:freshkey, :string)

      resolve(&R.Statistics.online_status/3)
    end

    @desc "basic site info in total counts format"
    field :count_status, :count_status_info do
      middleware(M.Passport, claim: "cms->root")

      resolve(&R.Statistics.count_status/3)
    end
  end
end
