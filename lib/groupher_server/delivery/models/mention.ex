defmodule GroupherServer.Delivery.Model.Mention do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.Accounts.Model.User

  @required_fields ~w(from_user_id to_user_id title article_id thread)a
  @optional_fields ~w(comment_id read)a

  @type t :: %Mention{}
  schema "mentions" do
    field(:thread, :string)
    field(:article_id, :id)
    field(:title, :string)
    field(:comment_id, :id)
    field(:read, :boolean)

    field(:block_linker, {:array, :string})

    belongs_to(:from_user, User)
    belongs_to(:to_user, User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Mention{} = mention, attrs) do
    mention
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:from_user_id)
    |> foreign_key_constraint(:to_user_id)
  end

  def update_changeset(%Mention{} = mention, attrs) do
    mention |> cast(attrs, @optional_fields ++ @required_fields)
  end
end
