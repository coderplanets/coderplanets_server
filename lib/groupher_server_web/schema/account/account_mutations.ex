defmodule GroupherServerWeb.Schema.Account.Mutations do
  @moduledoc """
  accounts mutations
  """
  use Helper.GqlSchemaSuite

  object :account_mutations do
    @desc "update user's profile"
    field :update_profile, :user do
      arg(:profile, non_null(:user_profile_input))
      arg(:social, :social_input)
      arg(:work_backgrounds, list_of(:work_background_input))
      arg(:education_backgrounds, list_of(:edu_background_input))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.update_profile/3)
    end

    field :github_signin, :token_info do
      arg(:code, non_null(:string))

      middleware(M.GithubUser)
      resolve(&R.Accounts.github_signin/3)
    end

    @doc "follow a user"
    field :follow, :user do
      arg(:user_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.follow/3)
    end

    @doc "undo follow to a user"
    field :undo_follow, :user do
      arg(:user_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.undo_follow/3)
    end

    @desc "create a favorites category"
    field :create_favorite_category, :favorites_category do
      arg(:title, non_null(:string))
      arg(:private, :boolean)
      arg(:desc, :string)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.create_favorite_category/3)
    end

    @desc "update a favorites category"
    field :update_favorite_category, :favorites_category do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:private, :boolean)
      arg(:desc, :string)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.update_favorite_category/3)
    end

    @desc "delete a favorites category"
    field :delete_favorite_category, :done do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.delete_favorite_category/3)
    end

    @desc "put content to favorites with category"
    field :set_favorites, :favorites_category do
      arg(:id, non_null(:id))
      arg(:category_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.set_favorites/3)
    end

    @desc "take out content from favorites category"
    field :unset_favorites, :favorites_category do
      arg(:id, non_null(:id))
      arg(:category_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :post)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.unset_favorites/3)
    end

    @desc "set user's customization"
    field :set_customization, :user do
      arg(:user_id, :id)
      arg(:customization, non_null(:customization_input))
      arg(:sidebar_communities_index, list_of(:community_index))

      resolve(&R.Accounts.set_customization/3)
    end

    @desc "mark a mention as read"
    field :mark_mention_read, :status do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.mark_mention_read/3)
    end

    @desc "mark a all unread mention as read"
    field :mark_mention_read_all, :status do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.mark_mention_read_all/3)
    end

    @desc "mark a notification as read"
    field :mark_notification_read, :status do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.mark_notification_read/3)
    end

    @desc "mark a all unread notifications as read"
    field :mark_notification_read_all, :status do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.mark_notification_read_all/3)
    end

    @desc "mark a system notification as read"
    field :mark_sys_notification_read, :status do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.mark_sys_notification_read/3)
    end
  end
end
