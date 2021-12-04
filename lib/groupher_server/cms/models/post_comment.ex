defmodule GroupherServer.CMS.Model.PostComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.{Accounts, CMS}
  alias CMS.Model.Post

  alias Helper.HTML

  @required_fields ~w(body author_id post_id floor)a
  @optional_fields ~w(reply_id)a

  @type t :: %PostComment{}
  schema "posts_comments" do
    field(:body, :string)
    field(:floor, :integer)
    belongs_to(:author, Accounts.Model.User, foreign_key: :author_id)
    belongs_to(:post, Post, foreign_key: :post_id)

    timestamps()
  end

  @doc false
  def changeset(%PostComment{} = post_comment, attrs) do
    post_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%PostComment{} = post_comment, attrs) do
    post_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:author_id)
    |> validate_length(:body, min: 3, max: 2000)
  end
end
