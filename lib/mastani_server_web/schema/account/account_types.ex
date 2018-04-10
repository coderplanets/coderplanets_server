defmodule MastaniServerWeb.Schema.Account.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  import Absinthe.Resolution.Helpers

  alias MastaniServer.Accounts
  alias MastaniServerWeb.Schema

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
    field(:bio, :string)
    field(:avatar, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
    field(:from_github, :boolean)
    field(:github, :github_profile, resolve: dataloader(Accounts, :github_profile))
    # TODO: default is to load recent 1 month
    # field :recent_contributes, list_of(:contribute) do
    # resolve(&Resolvers.Statistics.list_contributes/3)
    # end
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
