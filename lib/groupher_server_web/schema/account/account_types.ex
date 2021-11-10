defmodule GroupherServerWeb.Schema.Account.Types do
  @moduledoc """
  accounts GraphQL commont types
  """
  use Helper.GqlSchemaSuite

  import GroupherServerWeb.Schema.Helper.Fields
  import Absinthe.Resolution.Helpers

  alias GroupherServer.Accounts
  alias GroupherServerWeb.Schema

  import_types(Schema.Account.Metrics)

  object :session_state do
    field(:user, :user)
    field(:is_valid, :boolean)
  end

  object :user_meta do
    field(:reported_count, :integer)
    field(:is_maker, :boolean)
    field(:published_posts_count, :integer)
    field(:published_jobs_count, :integer)
    field(:published_radars_count, :integer)
    field(:published_blogs_count, :integer)
    field(:published_works_count, :integer)
    field(:published_meetups_count, :integer)

    # aduit
    field(:has_illegal_articles, :boolean)
    field(:has_illegal_comments, :boolean)

    field(:illegal_articles, list_of(:string))
    field(:illegal_comments, list_of(:string))
  end

  object :user do
    meta(:cache, max_age: 30)
    field(:meta, :user_meta)
    field(:id, :id)
    field(:nickname, :string)
    field(:login, :string)
    field(:avatar, :string)
    field(:bio, :string)
    field(:shortbio, :string)
    field(:sex, :string)
    field(:email, :string)

    field(:location, :string)
    field(:geo_city, :string)

    field(:views, :integer)
    field(:social, :social_map, resolve: dataloader(Accounts, :social))

    field(:from_github, :boolean)
    field(:github_profile, :github_profile, resolve: dataloader(Accounts, :github_profile))
    # field(:achievement, :achievement, resolve: dataloader(Accounts, :achievement))

    field(:achievement, :achievement) do
      resolve(dataloader(Accounts, :achievement))
      middleware(M.AchievementProof)
    end

    field(:customization, :customization) do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.get_customization/3)
    end

    field(:education_backgrounds, list_of(:education_background))
    field(:work_backgrounds, list_of(:work_background))

    field(:cms_passport_string, :string) do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.get_passport_string/3)
    end

    field(:cms_passport, :json) do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.get_passport/3)
    end

    field(:subscribed_communities_count, :integer)

    @desc "get follower users count"
    field(:followers_count, :integer)

    @desc "get following users count"
    field(:followings_count, :integer)

    @desc "if viewer has followed"
    field(:viewer_has_followed, :boolean)
    @desc "if viewer has been followed"
    field(:viewer_been_followed, :boolean)

    field(:contributes, :contribute_map)

    # TODO, for msg-bell UI
    # field :has_messges,
    # 1. has_mentions ?
    # 2. has_system_messages ?
    # 3. has_notifications ?
    # 4. has_watches ?

    field :mailbox, :mailbox_status do
      middleware(M.Authorize, :login)
      resolve(&R.Accounts.mailbox_status/3)
    end

    timestamp_fields()
  end

  object :mailbox_status do
    field(:is_empty, :boolean)
    field(:unread_total_count, :integer)
    field(:unread_mentions_count, :integer)
    field(:unread_notifications_count, :integer)
  end

  object :mailbox_mention do
    field(:id, :id)
    field(:thread, :string)
    field(:article_id, :id)
    field(:title, :string)
    field(:comment_id, :id)
    field(:read, :boolean)

    field(:block_linker, list_of(:string))

    field(:user, :common_user)

    timestamp_fields()
  end

  object :mailbox_notification do
    field(:id, :id)
    field(:action, :string)
    field(:thread, :string)
    field(:article_id, :id)
    field(:title, :string)
    field(:comment_id, :id)
    field(:read, :boolean)

    field(:from_users, list_of(:common_user))
    field(:from_users_count, :integer)

    timestamp_fields()
  end

  # field(:sidebar_layout, :map)
  object :customization do
    field(:theme, :string)
    field(:community_chart, :boolean)
    field(:brainwash_free, :boolean)

    field(:banner_layout, :string)
    field(:contents_layout, :string)
    field(:content_divider, :boolean)
    field(:content_hover, :boolean)
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

  object :education_background do
    field(:school, :string)
    field(:major, :string)
  end

  object :work_background do
    field(:company, :string)
    field(:title, :string)
  end

  object :social_map do
    social_fields()
  end

  object :collect_folder_meta do
    collect_folder_meta_fields()
  end

  object :collect_folder do
    field(:id, :id)
    field(:title, :string)
    field(:desc, :string)
    field(:index, :integer)
    field(:total_count, :integer)
    field(:private, :boolean)
    field(:last_updated, :datetime)
    field(:meta, :collect_folder_meta)

    timestamp_fields()
  end

  object :paged_collect_folders do
    field(:entries, list_of(:collect_folder))
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
    field(:articles_upvotes_count, :integer)
    field(:articles_collects_count, :integer)
    # field(:contents_watched_count, :integer)

    field(:source_contribute, :source_contribute)
    field(:donate_member, :boolean)
    field(:senior_member, :boolean)
    field(:sponsor_member, :boolean)
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

  object :paged_mailbox_mentions do
    field(:entries, list_of(:mailbox_mention))
    pagination_fields()
  end

  object :paged_mailbox_notifications do
    field(:entries, list_of(:mailbox_notification))
    pagination_fields()
  end

  enum :mailbox_type do
    value(:mention)
    value(:notification)
  end
end
