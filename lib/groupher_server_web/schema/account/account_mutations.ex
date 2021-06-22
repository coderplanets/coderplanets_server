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

    @desc "follow a user"
    field :follow, :user do
      arg(:login, non_null(:string))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.follow/3)
    end

    @desc "unfollow a user"
    field :undo_follow, :user do
      arg(:login, non_null(:string))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.undo_follow/3)
    end

    @desc "create a collect folder"
    field :create_collect_folder, :collect_folder do
      arg(:title, non_null(:string))
      arg(:private, :boolean)
      arg(:desc, :string)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.create_collect_folder/3)
    end

    @desc "update a collect folder"
    field :update_collect_folder, :collect_folder do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:private, :boolean)
      arg(:desc, :string)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.update_collect_folder/3)
    end

    @desc "delete a collect folder"
    field :delete_collect_folder, :collect_folder do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.delete_collect_folder/3)
    end

    @desc "add article into a collect folder"
    field :add_to_collect, :collect_folder do
      arg(:article_id, non_null(:id))
      arg(:folder_id, non_null(:id))
      arg(:thread, :thread, default_value: :post)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.add_to_collect/3)
    end

    @desc "remove article from a collect folder"
    field :remove_from_collect, :collect_folder do
      arg(:article_id, non_null(:id))
      arg(:folder_id, non_null(:id))
      arg(:thread, :thread, default_value: :post)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.remove_from_collect/3)
    end

    @desc "set user's customization"
    field :set_customization, :user do
      arg(:user_id, :id)
      arg(:customization, non_null(:customization_input))
      arg(:sidebar_communities_index, list_of(:community_index))

      resolve(&R.Accounts.set_customization/3)
    end

    @desc "mark a message as read"
    field :mark_read, :done do
      arg(:ids, list_of(:id))
      arg(:type, :mailbox_type, default_value: :mention)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.mark_read/3)
    end

    @desc "mark all unread message as read"
    field :mark_read_all, :done do
      arg(:type, :mailbox_type, default_value: :mention)

      middleware(M.Authorize, :login)
      resolve(&R.Accounts.mark_read_all/3)
    end
  end
end
