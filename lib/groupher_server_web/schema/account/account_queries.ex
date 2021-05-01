defmodule GroupherServerWeb.Schema.Account.Queries do
  @moduledoc """
  accounts GraphQL queries
  """
  use Helper.GqlSchemaSuite

  object :account_queries do
    @desc "get all users"
    field :paged_users, non_null(:paged_users) do
      arg(:filter, non_null(:paged_users_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.users/3)
    end

    @desc "get user by id"
    field :user, :user do
      # arg(:id, :id)
      arg(:login, :string)

      resolve(&R.Accounts.user/3)
    end

    @desc "check the cur token is valid or not"
    field :session_state, :session_state do
      resolve(&R.Accounts.session_state/3)
    end

    @desc "anyone can get anyone's subscribed communities"
    field :subscribed_communities, :paged_communities do
      arg(:user_id, :id)
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.subscribed_communities/3)
    end

    @desc "get user's mentions"
    field :mentions, :paged_mentions do
      arg(:filter, :messages_filter)

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)
      resolve(&R.Accounts.fetch_mentions/3)
    end

    @desc "get user's follower"
    field :paged_followers, :paged_users do
      arg(:user_id, :id)
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_followers/3)
    end

    @desc "get user's follower"
    field :paged_followings, :paged_users do
      arg(:user_id, :id)
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_followings/3)
    end

    @desc "get favorites categoories"
    field :favorite_categories, :paged_favorites_categories do
      arg(:user_id, :id)
      arg(:filter, non_null(:common_paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.list_favorite_categories/3)
    end

    field :upvoted_articles, :paged_articles do
      arg(:thread, :cms_thread, default_value: :post)
      # arg(:thread, :cms_thread)

      resolve(&R.Accounts.upvoted_articles/3)
    end

    @desc "get favorited posts"
    field :favorited_posts, :paged_posts do
      arg(:user_id, non_null(:id))
      arg(:filter, non_null(:paged_filter))
      arg(:category_id, :id)
      arg(:thread, :post_thread, default_value: :post)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.favorited_contents/3)
    end

    @desc "get favorited jobs"
    field :favorited_jobs, :paged_jobs do
      arg(:user_id, non_null(:id))
      arg(:filter, non_null(:paged_filter))
      arg(:category_id, :id)
      arg(:thread, :job_thread, default_value: :job)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.favorited_contents/3)
    end

    @desc "get favorited repos"
    field :favorited_repos, :paged_repos do
      arg(:user_id, non_null(:id))
      arg(:filter, non_null(:paged_filter))
      arg(:category_id, :id)
      arg(:thread, :repo_thread, default_value: :repo)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.favorited_contents/3)
    end

    @desc "get paged published posts"
    field :published_posts, :paged_posts do
      arg(:user_id, non_null(:id))
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :post_thread, default_value: :post)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.published_contents/3)
    end

    @desc "get paged published jobs"
    field :published_jobs, :paged_jobs do
      arg(:user_id, non_null(:id))
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :job_thread, default_value: :job)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.published_contents/3)
    end

    @desc "get paged published repos"
    field :published_repos, :paged_repos do
      arg(:user_id, non_null(:id))
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :repo_thread, default_value: :repo)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.published_contents/3)
    end

    @desc "get paged published comments on post"
    field :published_post_comments, :paged_post_comments do
      arg(:user_id, non_null(:id))
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :post_thread, default_value: :post)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.published_comments/3)
    end

    @desc "paged communities which the user it's the editor"
    field :editable_communities, :paged_communities do
      arg(:user_id, :id)
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.editable_communities/3)
    end

    @desc "get all passport rules include system and community etc ..."
    field :all_passport_rules_string, :rules do
      middleware(M.Authorize, :login)

      resolve(&R.Accounts.get_all_rules/3)
    end

    @desc "search user by name"
    field :search_users, :paged_users do
      arg(:name, non_null(:string))

      resolve(&R.Accounts.search_users/3)
    end
  end
end
