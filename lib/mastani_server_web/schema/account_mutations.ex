defmodule MastaniServerWeb.Schema.Account.Mutations do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  alias MastaniServerWeb.Resolvers.Accounts

  object :account_mutations do
    @desc "hehehef: create a user"
    field :create_user, :user do
      arg(:username, non_null(:string))
      arg(:nickname, non_null(:string))
      arg(:bio, non_null(:string))
      arg(:company, non_null(:string))

      resolve(&Accounts.create_user/3)
    end
  end
end
