defmodule MastaniServer.CMS.Author do
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.Post
  alias MastaniServer.Accounts

  schema "cms_authors" do
    field(:role, :string)
    # field(:user_id, :id)
    has_many(:posts, Post)
    # user_id filed in own-table
    belongs_to(:user, Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Author{} = author, attrs) do
    # |> foreign_key_constraint(:user_id)
    author
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> unique_constraint(:user_id)
  end
end
