defmodule GroupherServerWeb.Schema.Account.Metrics do
  @moduledoc false

  use Absinthe.Schema.Notation
  import GroupherServerWeb.Schema.Helper.Fields

  input_object :mailbox_mentions_filter do
    field(:read, :boolean, default_value: false)
    pagination_args()
  end

  input_object :mailbox_notifications_filter do
    field(:read, :boolean, default_value: false)
    pagination_args()
  end

  @desc "article_filter doc"
  input_object :paged_users_filter do
    pagination_args()
    # field(:when, :when_enum)
    # field(:sort, :sort_enum)
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

  input_object :work_background_input do
    field(:company, :string)
    field(:title, :string)
  end

  input_object :edu_background_input do
    field(:school, :string)
    field(:major, :string)
  end

  input_object :user_profile_input do
    field(:avatar, :string)
    field(:nickname, :string)
    field(:bio, :string)
    field(:shortbio, :string)
    field(:sex, :string)
    field(:location, :string)
    field(:email, :string)
  end

  input_object :social_input do
    social_fields()
  end

  enum :cus_banner_layout_num do
    value(:digest)
    value(:brief)
  end

  enum :cus_contents_layout_num do
    value(:digest)
    value(:list)
  end

  input_object :customization_input do
    field(:theme, :string)
    field(:community_chart, :boolean)
    field(:brainwash_free, :boolean)

    field(:banner_layout, :cus_banner_layout_num)
    field(:contents_layout, :cus_contents_layout_num)
    field(:content_divider, :boolean)
    field(:content_hover, :boolean)
    field(:mark_viewed, :boolean)
    field(:display_density, :string)
  end

  input_object :community_index do
    field(:community, :string)
    field(:index, :integer)
  end

  # see: https://github.com/absinthe-graphql/absinthe/issues/206
  # https://github.com/absinthe-graphql/absinthe/wiki/Scalar-Recipes
  scalar :json, name: "Json" do
    description("""
    The `Json` scalar type represents arbitrary json string data, represented as UTF-8
    character sequences. The Json type is most often used to represent a free-form
    human-readable json string.
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end

  defp encode(value), do: value
end
