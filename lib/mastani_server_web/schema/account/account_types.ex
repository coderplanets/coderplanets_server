defmodule MastaniServerWeb.Schema.Account.Types do
  use Helper.GqlSchemaSuite

  import MastaniServerWeb.Schema.Utils.Helper
  import Absinthe.Resolution.Helpers

  alias MastaniServer.Accounts
  alias MastaniServerWeb.Schema

  import_types(Schema.Account.Misc)

  object :session_state do
    field(:user, :user)
    field(:is_valid, :boolean)
  end

  object :education_background do
    field(:school, :string)
    field(:major, :string)
  end

  object :work_background do
    field(:company, :string)
    field(:title, :string)
  end

  object :user do
    field(:id, :id)
    field(:nickname, :string)
    field(:avatar, :string)
    field(:bio, :string)
    field(:sex, :string)
    field(:email, :string)
    field(:location, :string)
    field(:geo_city, :string)

    field(:views, :integer)

    sscial_fields()

    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
    field(:from_github, :boolean)
    field(:github_profile, :github_profile, resolve: dataloader(Accounts, :github_profile))
    field(:achievement, :achievement, resolve: dataloader(Accounts, :achievement))

    field(:customization, :customization) do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.get_customization/3)
    end

    field(:education_backgrounds, list_of(:education_background))
    field(:work_backgrounds, list_of(:work_background))

    # field(:favorites_categories, :paged_favorites_category) do
    # arg(:filter, non_null(:common_paged_filter))

    # middleware(M.Authorize, :login)
    # middleware(M.PageSizeProof)
    # resolve(&R.Accounts.list_favorite_categories/3)
    # end

    field(:cms_passport_string, :string) do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.get_passport_string/3)
    end

    field(:cms_passport, :json) do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.get_passport/3)
    end

    # field :subscribed_communities, list_of(:community) do
    # arg(:filter, :members_filter)

    # middleware(M.PageSizeProof)
    # resolve(dataloader(Accounts, :subscribed_communities))
    # end
    @desc "paged communities subscribed by this user"
    field :subscribed_communities, :paged_communities do
      arg(:filter, :paged_filter)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.subscribed_communities/3)
    end

    field :subscribed_communities_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :subscribed_communities))
      middleware(M.ConvertToInt)
    end

    @desc "paged communities which the user it's the editor"
    field :editable_communities, :paged_communities do
      # arg(:filter, non_null(:paged_filter))
      arg(:filter, :paged_filter)

      # middleware(M.SeeMe)
      middleware(M.PageSizeProof)
      resolve(&R.Accounts.editable_communities/3)
    end

    @doc "get follower users count"
    field :followers_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :followers))
      middleware(M.ConvertToInt)
    end

    @doc "get following users count"
    field :followings_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :followings))
      middleware(M.ConvertToInt)
    end

    @doc "wether viewer has followed"
    field :viewer_has_followed, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      middleware(M.PutCurrentUser)
      resolve(dataloader(Accounts, :followers))
      middleware(M.ViewerDidConvert)
    end

    @doc "paged stared posts"
    field :stared_posts, :paged_posts do
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :post_thread, default_value: :post)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.stared_contents/3)
    end

    @doc "paged stared jobs"
    field :stared_jobs, :paged_jobs do
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :job_thread, default_value: :job)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.stared_contents/3)
    end

    @doc "paged stared videos"
    field :stared_videos, :paged_videos do
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :video_thread, default_value: :video)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.stared_contents/3)
    end

    @doc "paged favorited posts"
    field :favorited_posts, :paged_posts do
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :post_thread, default_value: :post)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.favorited_contents/3)
    end

    @doc "paged favorited jobs"
    field :favorited_jobs, :paged_jobs do
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :job_thread, default_value: :job)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.favorited_contents/3)
    end

    @doc "paged favorited videos"
    field :favorited_videos, :paged_videos do
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :video_thread, default_value: :video)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.favorited_contents/3)
    end

    @doc "paged favorited repos"
    field :favorited_repos, :paged_repos do
      arg(:filter, non_null(:paged_filter))
      arg(:thread, :repo_thread, default_value: :repo)

      middleware(M.PageSizeProof)
      resolve(&R.Accounts.favorited_contents/3)
    end

    @doc "total count of stared posts count"
    field :stared_posts_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :stared_posts))
      middleware(M.ConvertToInt)
    end

    @doc "total count of stared jobs count"
    field :stared_jobs_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :stared_jobs))
      middleware(M.ConvertToInt)
    end

    @doc "total count of stared videos count"
    field :stared_videos_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :stared_videos))
      middleware(M.ConvertToInt)
    end

    @doc "total count of favorited posts count"
    field :favorited_posts_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :favorited_posts))
      middleware(M.ConvertToInt)
    end

    @doc "total count of favorited jobs count"
    field :favorited_jobs_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :favorited_jobs))
      middleware(M.ConvertToInt)
    end

    @doc "total count of favorited videos count"
    field :favorited_videos_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :favorited_videos))
      middleware(M.ConvertToInt)
    end

    @doc "total count of favorited videos count"
    field :favorited_repos_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :favorited_repos))
      middleware(M.ConvertToInt)
    end

    field :contributes, :contribute_map do
      resolve(&R.Statistics.list_contributes/3)
    end

    # TODO, for msg-bell UI
    # field :has_messges,
    # 1. has_mentions ?
    # 2. has_system_messages ?
    # 3. has_notifications ?
    # 4. has_watches ?

    field :mail_box, :mail_box_status do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.get_mail_box_status/3)
    end

    field :mentions, :paged_mentions do
      arg(:filter, :messages_filter)

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)
      resolve(&R.Accounts.fetch_mentions/3)
    end

    field :notifications, :paged_notifications do
      arg(:filter, :messages_filter)

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)
      resolve(&R.Accounts.fetch_notifications/3)
    end

    field :sys_notifications, :paged_sys_notifications do
      arg(:filter, :messages_filter)

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)
      resolve(&R.Accounts.fetch_sys_notifications/3)
    end
  end

  # field(:sidebar_layout, :map)
  object :customization do
    field(:theme, :string)
    field(:community_chart, :boolean)
    field(:brainwash_free, :boolean)

    field(:banner_layout, :string)
    field(:contents_layout, :string)
    field(:content_divider, :boolean)
    field(:mark_viewed, :boolean)
    field(:display_density, :string)
  end

  object :github_profile do
    field(:id, :id)
    field(:github_id, :string)
    # field(:user, :user, resolve: dataloader(Accounts, :user))
    field(:login, :string)
    field(:avatar_url, :string)
    field(:url, :string)
    field(:html_url, :string)
    field(:name, :string)
    field(:company, :string)
    field(:blog, :string)
    field(:location, :string)
    field(:email, :string)
    field(:bio, :string)
    field(:public_repos, :integer)
    field(:public_gists, :integer)
  end

  object :favorites_category do
    field(:id, :id)
    field(:title, :string)
    field(:desc, :string)
    field(:index, :integer)
    field(:total_count, :integer)
    field(:private, :boolean)
    field(:last_updated, :datetime)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :paged_favorites_categories do
    field(:entries, list_of(:favorites_category))
    pagination_fields()
  end

  object :source_contribute do
    field(:web, :boolean)
    field(:server, :boolean)
    field(:we_app, :boolean)
    field(:h5, :boolean)
    field(:mobile, :boolean)
  end

  object :achievement do
    field(:reputation, :integer)
    # field(:followers_count, :integer)
    field(:contents_stared_count, :integer)
    field(:contents_favorited_count, :integer)
    # field(:contents_watched_count, :integer)

    field(:source_contribute, :source_contribute)
  end

  object :token_info do
    field(:token, :string)
    field(:user, :user)
  end

  object :rules do
    field(:cms, :json)
  end

  object :paged_users do
    field(:entries, list_of(:user))
    pagination_fields()
  end
end
