defmodule GroupherServer.CMS.Model.Author do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.Accounts
  alias Accounts.Model.User

  @type t :: %Author{}

  schema "cms_authors" do
    # field(:role, :string)
    # field(:user_id, :id)
    # has_many(:posts, Post)
    # user_id filed in own-table
    belongs_to(:user, User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Author{} = author, _attrs) do
    # |> foreign_key_constraint(:user_id)
    author
    # |> cast(attrs, [:role])
    # |> validate_required([:role])
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
