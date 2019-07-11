defmodule GroupherServer.CMS.JobCommentDislike do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}
  alias CMS.JobComment

  @required_fields ~w(job_comment_id user_id)a

  @type t :: %JobCommentDislike{}
  schema "jobs_comments_dislikes" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:job_comment, JobComment, foreign_key: :job_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%JobCommentDislike{} = job_comment_dislike, attrs) do
    job_comment_dislike
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:job_comment_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :jobs_comments_dislikes_user_id_job_comment_id_index)
  end
end
