defmodule MastaniServerWeb.Schema.Account.Misc do
  @moduledoc false

  use Absinthe.Schema.Notation
  import MastaniServerWeb.Schema.Utils.Helper
  # import Helper.Utils, only: [get_config: 2]
  # @page_size get_config(:general, :page_size)

  @desc "article_filter doc"
  input_object :paged_users_filter do
    pagination_args()
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

  input_object :work_background_input do
    field(:company, :string)
    field(:title, :string)
  end

  input_object :edu_background_input do
    field(:school, :string)
    field(:major, :string)
  end

  input_object :user_profile_input do
    field(:nickname, :string)
    field(:bio, :string)
    field(:sex, :string)
    field(:location, :string)
    field(:email, :string)
    # social
    sscial_fields()
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
