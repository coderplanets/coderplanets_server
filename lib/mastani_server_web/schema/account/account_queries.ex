defmodule MastaniServerWeb.Schema.Account.Queries do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo
  # import Absinthe.Resolution.Helpers
  alias MastaniServerWeb.Resolvers
  alias MastaniServerWeb.Middleware, as: M

  object :account_queries do
    @desc "get all users"
    field :paged_users, non_null(:paged_users) do
      arg(:filter, non_null(:paged_users_filter))

      middleware(M.PageSizeProof)
      resolve(&Resolvers.Accounts.users/3)
    end

    @desc "get user by id"
    field :user, :user do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Accounts.user/3)
    end

    @desc "get login-user's info"
    field :account, :user do
      middleware(M.Authorize, :login)

      resolve(&Resolvers.Accounts.account/3)
    end

    @desc "anyone can get anyone's subscribed communities"
    field :subscribed_communities, :paged_communities do
      arg(:user_id, :id)
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&Resolvers.Accounts.subscribed_communities/3)
    end

    @desc "get favorited posts"
    field :favorited_posts, :paged_posts do
      arg(:user_id, :id)
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&Resolvers.Accounts.favorited_posts/3)
    end

    @desc "get favorited jobs"
    field :favorited_jobs, :paged_jobs do
      arg(:user_id, :id)
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&Resolvers.Accounts.favorited_jobs/3)
    end

    @desc "get all passport rules include system and community etc ..."
    field :all_passport_rules_string, :rules do
      middleware(M.Authorize, :login)

      resolve(&Resolvers.Accounts.get_all_rules/3)
    end
  end
end
