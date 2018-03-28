defmodule MastaniServerWeb.Schema.Account.Mutations do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  alias MastaniServerWeb.Resolvers
  alias MastaniServerWeb.Middleware

  object :account_mutations do
    # @desc "hehehef: create a user"
    # field :create_user, :user do
    # arg(:username, non_null(:string))
    # arg(:nickname, non_null(:string))
    # arg(:bio, non_null(:string))
    # arg(:company, non_null(:string))

    # resolve(&Resolvers.Accounts.create_user/3)
    # end

    field :github_signin, :token_info do
      arg(:code, non_null(:string))
      # arg(:profile, non_null(:github_profile_input))

      middleware(Middleware.GithubUser)
      resolve(&Resolvers.Accounts.github_signin/3)
    end
  end
end
