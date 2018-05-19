defmodule MastaniServerWeb.Schema.Account.Misc do
  use Absinthe.Schema.Notation

  import Helper.Utils, only: [get_config: 2]
  @page_size get_config(:general, :page_size)

  @desc "article_filter doc"
  input_object :paged_users_filter do
    field(:page, :integer, default_value: 1)
    field(:size, :integer, default_value: @page_size)

    # field(:when, :when_enum)
    # field(:sort, :sort_enum)
    # field(:tag, :string, default_value: :all)
    # field(:community, :string)
  end

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

  input_object :user_profile_input do
    field(:nickname, :string)
    field(:bio, :string)
    field(:sex, :string)
    field(:education, :string)
    field(:location, :string)
    field(:company, :string)
    field(:email, :string)
    field(:qq, :string)
    field(:weibo, :string)
    field(:weichat, :string)
  end
end
