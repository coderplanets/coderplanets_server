defmodule MastaniServerWeb.Schema.Account.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  import MastaniServerWeb.Schema.Utils.Helper
  import Absinthe.Resolution.Helpers

  alias MastaniServer.Accounts
  alias MastaniServerWeb.{Resolvers, Schema}
  alias MastaniServerWeb.Middleware, as: M

  import_types(Schema.Account.Misc)

  object :github_profile do
    field(:id, :id)
    field(:github_id, :string)
    field(:user, :user, resolve: dataloader(Accounts, :user))
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

  object :user do
    field(:id, :id)
    field(:nickname, :string)
    field(:avatar, :string)
    field(:bio, :string)
    field(:sex, :string)
    field(:email, :string)
    field(:location, :string)
    field(:education, :string)
    field(:company, :string)
    field(:qq, :string)
    field(:weibo, :string)
    field(:weichat, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
    field(:from_github, :boolean)
    field(:github_profile, :github_profile, resolve: dataloader(Accounts, :github_profile))

    field(:cms_passport_string, :string) do
      middleware(M.Authorize, :login)
      resolve(&Resolvers.Accounts.get_passport_string/3)
    end

    field(:cms_passport, :json) do
      middleware(M.Authorize, :login)
      resolve(&Resolvers.Accounts.get_passport/3)
    end

    field :subscribed_communities, list_of(:community) do
      arg(:filter, :members_filter)

      middleware(M.PageSizeProof)
      resolve(dataloader(Accounts, :subscribed_communities))
    end

    field :subscribed_communities_count, :integer do
      arg(:count, :count_type, default_value: :count)

      resolve(dataloader(Accounts, :subscribed_communities))
      middleware(M.ConvertToInt)
    end

    field :contributes, :contribute_map do
      resolve(&Resolvers.Statistics.list_contributes/3)
    end

    # TODO, for msg-bell UI
    # field :has_messges,
    # 1. has_mentions ?
    # 2. has_system_messages ?
    # 3. has_notifications ?
    # 4. has_watches ?

    field :mail_box, :mail_box_status do
      middleware(M.Authorize, :login)
      resolve(&Resolvers.Accounts.get_mail_box_status/3)
    end

    field :mentions, :paged_mentions do
      arg(:filter, :messages_filter)

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)
      resolve(&Resolvers.Accounts.fetch_mentions/3)
      middleware(M.FormatPagination)
    end

    field :notifications, :paged_notifications do
      arg(:filter, :messages_filter)

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)
      resolve(&Resolvers.Accounts.fetch_notifications/3)
      middleware(M.FormatPagination)
    end

    field :sys_notifications, :paged_sys_notifications do
      arg(:filter, :messages_filter)

      middleware(M.Authorize, :login)
      middleware(M.PageSizeProof)
      resolve(&Resolvers.Accounts.fetch_sys_notifications/3)
      middleware(M.FormatPagination)
    end
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
