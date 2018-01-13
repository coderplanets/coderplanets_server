defmodule MastaniServer.CMS.PostComment do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts
  alias MastaniServer.CMS.{Post, PostComment}

  @required_fields ~w(body author_id post_id)a

  schema "posts_comments" do
    field(:body, :string)
    belongs_to(:author, Accounts.User, foreign_key: :author_id)
    belongs_to(:post, Post)

    timestamps()
  end

  @doc false
  def changeset(%PostComment{} = post_comment, attrs) do
    post_comment
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:author_id)
  end
end
