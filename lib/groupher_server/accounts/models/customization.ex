defmodule GroupherServer.Accounts.Model.Customization do
  @moduledoc false

  alias __MODULE__
  use Ecto.Schema

  import Helper.Utils, only: [get_config: 2]
  import Ecto.Changeset

  alias GroupherServer.Accounts.Model.User

  @required_fields ~w(user_id)a
  @optional_fields ~w(theme sidebar_layout sidebar_communities_index community_chart brainwash_free banner_layout contents_layout content_divider content_hover mark_viewed display_density)a

  @default_customization get_config(:customization, :all)

  @type t :: %Customization{}
  schema "customizations" do
    belongs_to(:user, User)

    field(:theme, :string)
    field(:sidebar_layout, :map)
    field(:sidebar_communities_index, :map)

    field(:community_chart, :boolean)
    field(:brainwash_free, :boolean)

    field(:banner_layout, :string)
    field(:contents_layout, :string)
    field(:content_divider, :boolean)
    field(:content_hover, :boolean)
    field(:mark_viewed, :boolean)
    field(:display_density, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Customization{} = customization, attrs) do
    customization
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
  end

  def default, do: @default_customization |> Enum.into(%{})
end
