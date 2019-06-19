defmodule GroupherServer.CMS.PostComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts

  alias GroupherServer.CMS.{
    Post,
    PostCommentDislike,
    PostCommentLike,
    PostCommentReply
  }

  @required_fields ~w(body author_id post_id floor)a
  @optional_fields ~w(reply_id)a

  @type t :: %PostComment{}
  schema "posts_comments" do
    field(:body, :string)
    field(:floor, :integer)
    belongs_to(:author, Accounts.User, foreign_key: :author_id)
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:reply_to, PostComment, foreign_key: :reply_id)

    has_many(:replies, {"posts_comments_replies", PostCommentReply})
    has_many(:likes, {"posts_comments_likes", PostCommentLike})
    has_many(:dislikes, {"posts_comments_dislikes", PostCommentDislike})

    timestamps(type: :utc_datetime)
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

  @doc false
  def update_changeset(%PostComment{} = post_comment, attrs) do
    post_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:author_id)
  end
end
