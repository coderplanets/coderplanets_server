defmodule MastaniServerWeb.Schema.Account.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  alias MastaniServerWeb.Resolvers.Accounts

  object :account_queries do
    @desc "hehehef: Get all links"
    field :all_users, non_null(list_of(non_null(:user))) do
      resolve(&Accounts.all_users/3)
    end

    field :all_users2, non_null(:paged_users) do
      resolve(&Accounts.all_users2/3)
    end
  end
end
