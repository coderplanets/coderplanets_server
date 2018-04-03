defmodule MastaniServerWeb.Schema.Statistics.Mutations do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  alias MastaniServerWeb.Resolvers
  # alias MastaniServerWeb.Middleware

  object :statistics_mutations do
    field :make_contrubute, :user_contribute do
      arg(:user_id, non_null(:id))

      resolve(&Resolvers.Statistics.make_contrubute/3)
    end
  end
end
