defmodule GroupherServer.CMS.RepoComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias CMS.{
    Repo,
    RepoCommentDislike,
    RepoCommentLike,
    RepoCommentReply
  }

  alias Helper.HTML

  @required_fields ~w(body author_id repo_id floor)a
  @optional_fields ~w(reply_id)a

  @type t :: %RepoComment{}
  schema "repos_comments" do
    field(:body, :string)
    field(:floor, :integer)
    belongs_to(:author, Accounts.User, foreign_key: :author_id)
    belongs_to(:repo, Repo, foreign_key: :repo_id)
    belongs_to(:reply_to, RepoComment, foreign_key: :reply_id)

    has_many(:replies, {"repos_comments_replies", RepoCommentReply})
    has_many(:likes, {"repos_comments_likes", RepoCommentLike})
    has_many(:dislikes, {"repos_comments_dislikes", RepoCommentDislike})

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%RepoComment{} = repo_comment, attrs) do
    repo_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%RepoComment{} = repo_comment, attrs) do
    repo_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> foreign_key_constraint(:repo_id)
    |> foreign_key_constraint(:author_id)
    |> validate_length(:body, min: 3, max: 2000)
    |> HTML.safe_string(:body)
  end
end
