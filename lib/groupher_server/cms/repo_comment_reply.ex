defmodule GroupherServer.CMS.RepoCommentReply do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.RepoComment

  @required_fields ~w(repo_comment_id reply_id)a

  @type t :: %RepoCommentReply{}
  schema "repos_comments_replies" do
    belongs_to(:repo_comment, RepoComment, foreign_key: :repo_comment_id)
    belongs_to(:reply, RepoComment, foreign_key: :reply_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%RepoCommentReply{} = repo_comment_reply, attrs) do
    repo_comment_reply
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:repo_comment_id)
    |> foreign_key_constraint(:reply_id)
  end
end
