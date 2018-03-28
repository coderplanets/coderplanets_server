defmodule MastaniServerWeb.Schema.Account.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo
  # import Absinthe.Resolution.Helpers
  alias MastaniServerWeb.Resolvers

  object :account_queries do
    # @desc "hehehef: Get all links"
    # field :all_users, non_null(list_of(non_null(:user))) do
    # resolve(&Accounts.all_users/3)
    # end

    @desc "get all users"
    # field :all_users, non_null(:paged_users) do
    # resolve(&Resolvers.Accounts.all_users2/3)
    # end

    @desc "get all users"
    field :user, :user do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Accounts.user/3)
    end
  end
end
