defmodule GroupherServer.CMS.Model.CommunityEditor do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.Community
  alias Helper.Certification

  @required_fields ~w(user_id community_id title)a

  @type t :: %CommunityEditor{}

  schema "communities_editors" do
    field(:title, :string)
    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommunityEditor{} = community_editor, attrs) do
    community_editor
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:title, Certification.editor_titles(:cms))
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :communities_editors_user_id_community_id_index)
  end
end
