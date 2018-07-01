defmodule MastaniServerWeb.Schema.Account.Mutations do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  alias MastaniServerWeb.Resolvers
  alias MastaniServerWeb.Middleware, as: M

  object :account_mutations do
    # @desc "hehehef: create a user"
    # field :create_user, :user do
    # arg(:username, non_null(:string))
    # arg(:nickname, non_null(:string))
    # arg(:bio, non_null(:string))
    # arg(:company, non_null(:string))

    # resolve(&Resolvers.Accounts.create_user/3)
    # end

    @desc "update user's profile"
    field :update_profile, :user do
      arg(:profile, non_null(:user_profile_input))
      middleware(M.Authorize, :login)

      resolve(&Resolvers.Accounts.update_profile/3)
    end

    field :github_signin, :token_info do
      arg(:code, non_null(:string))
      # arg(:profile, non_null(:github_profile_input))

      middleware(M.GithubUser)
      resolve(&Resolvers.Accounts.github_signin/3)
    end

    @desc "mark a mention as read"
    field :mark_mention_read, :mention do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.Accounts.mark_mention_read/3)
    end

    @desc "mark a all unread mention as read"
    field :mark_mention_read_all, :status do
      middleware(M.Authorize, :login)
      resolve(&Resolvers.Accounts.mark_mention_read_all/3)
    end
  end
end
