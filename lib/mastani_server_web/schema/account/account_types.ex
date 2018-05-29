defmodule MastaniServerWeb.Schema.Account.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  import Absinthe.Resolution.Helpers

  alias MastaniServer.Accounts
  alias MastaniServerWeb.{Resolvers, Schema}
  alias MastaniServerWeb.Middleware, as: M

  import_types(Schema.Account.Misc)

  object :page_info do
    field(:total_count, :integer)
    field(:page_size, :integer)
  end

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
  end

  object :token_info do
    field(:token, :string)
    field(:user, :user)
  end

  object :paged_users do
    field(:entries, list_of(:user))
    field(:total_count, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end
end
