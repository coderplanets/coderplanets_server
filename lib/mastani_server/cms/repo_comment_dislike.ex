defmodule MastaniServer.CMS.RepoCommentDislike do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts
  alias MastaniServer.CMS.RepoComment

  @required_fields ~w(repo_comment_id user_id)a

  @type t :: %RepoCommentDislike{}
  schema "repos_comments_dislikes" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:repo_comment, RepoComment, foreign_key: :repo_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%RepoCommentDislike{} = repo_comment_dislike, attrs) do
    repo_comment_dislike
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:repo_comment_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :repos_comments_dislikes_user_id_repo_comment_id_index)
  end
end
