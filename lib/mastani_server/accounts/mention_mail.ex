defmodule MastaniServer.Accounts.MentionMail do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts.User

  @required_fields ~w(from_user_id to_user_id source_id source_type source_preview)a
  @optional_fields ~w(parent_id parent_type read floor community)a

  @type t :: %MentionMail{}
  schema "mention_mails" do
    belongs_to(:from_user, User)
    belongs_to(:to_user, User)
    field(:source_id, :string)
    field(:source_preview, :string)
    field(:source_title, :string)
    field(:source_type, :string)
    field(:parent_id, :string)
    field(:parent_type, :string)
    field(:community, :string)
    field(:floor, :integer)
    field(:read, :boolean)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%MentionMail{} = mention, attrs) do
    mention
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:from_user_id)
    |> foreign_key_constraint(:to_user_id)
  end

  @doc false
  def update_changeset(%MentionMail{} = mention, attrs) do
    mention
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> foreign_key_constraint(:from_user_id)
    |> foreign_key_constraint(:to_user_id)
  end
end
