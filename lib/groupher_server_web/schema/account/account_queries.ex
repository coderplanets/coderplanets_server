defmodule GroupherServerWeb.Schema.Account.Queries do
  @moduledoc """
  accounts GraphQL queries
  """
  import GroupherServerWeb.Schema.Helper.Queries
  use Helper.GqlSchemaSuite

  object :account_queries do
    @desc "get all users"
    field :paged_users, non_null(:paged_users) do
      arg(:filter, non_null(:paged_users_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_users/3)
    end

    @desc "get user by id"
    field :user, :user do
      arg(:login, non_null(:string))

      resolve(&R.Accounts.user/3)
    end

    @desc "check the cur token is valid or not"
    field :session_state, :session_state do
      resolve(&R.Accounts.session_state/3)
    end

    @desc "anyone can get anyone's subscribed communities"
    field :subscribed_communities, :paged_communities do
      arg(:login, :string)
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.subscribed_communities/3)
    end

    @desc "get login user's mentions in mailbox"
    field :paged_mentions, :paged_mailbox_mentions do
      arg(:filter, :mailbox_mentions_filter)

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_mailbox_mentions/3)
    end

    @desc "get login user's notifications in mailbox"
    field :paged_notifications, :paged_mailbox_notifications do
      arg(:filter, :mailbox_notifications_filter)

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_mailbox_notifications/3)
    end

    @desc "get user's follower"
    field :paged_followers, :paged_users do
      arg(:login, non_null(:string))
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_followers/3)
    end

    @desc "get user's follower"
    field :paged_followings, :paged_users do
      arg(:login, non_null(:string))
      arg(:filter, non_null(:paged_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_followings/3)
    end

    @desc "get paged upvoted articles"
    field :paged_upvoted_articles, :paged_articles do
      arg(:login, non_null(:string))
      arg(:filter, :upvoted_articles_filter)

      resolve(&R.Accounts.paged_upvoted_articles/3)
    end

    @desc "get paged collect folders of a user"
    field :paged_collect_folders, :paged_collect_folders do
      arg(:login, non_null(:string))
      arg(:filter, non_null(:collect_folders_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_collect_folders/3)
    end

    @desc "get paged collected articles"
    field :paged_collected_articles, :paged_articles do
      arg(:folder_id, non_null(:id))
      arg(:filter, non_null(:collected_articles_filter))

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_collected_articles/3)
    end

    @desc "paged communities which the user it's the editor"
    field :editable_communities, :paged_communities do
      arg(:login, :string)
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

    @desc "get paged published article comments"
    field :paged_published_comments, :paged_comments do
      arg(:login, non_null(:string))
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :thread, default_value: :post)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.paged_published_comments/3)
    end

    published_article_queries()
  end
end
