defmodule MastaniServerWeb.Schema.Account.Misc do
  use Absinthe.Schema.Notation
  # alias MastaniServer.Accounts

  input_object :github_profile_input do
    # is github_id in db table
    field(:id, non_null(:string))
    field(:login, non_null(:string))
    field(:avatar_url, non_null(:string))
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
end
