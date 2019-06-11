defmodule GroupherServer.CMS.RepoCommentLike do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.RepoCommentLike

  @required_fields ~w(repo_comment_id user_id)a

  @type t :: %RepoCommentLike{}
  schema "repos_comments_likes" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:repo_comment, RepoCommentLike, foreign_key: :repo_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%RepoCommentLike{} = repo_comment_like, attrs) do
    repo_comment_like
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:repo_comment_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :repos_comments_likes_user_id_repo_comment_id_index)
  end
end
