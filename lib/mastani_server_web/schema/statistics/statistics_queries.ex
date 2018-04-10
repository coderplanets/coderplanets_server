defmodule MastaniServerWeb.Schema.Statistics.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo
  # import Absinthe.Resolution.Helpers
  alias MastaniServerWeb.{Resolvers}

  object :statistics_queries do
    @desc "list of user contribute in last 6 month"
    field :user_contributes, list_of(:user_contribute) do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Statistics.list_contributes/3)
    end
  end
end
