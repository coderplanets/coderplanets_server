defmodule MastaniServer.CMS.JobCommentLike do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts
  alias MastaniServer.CMS.JobComment

  @required_fields ~w(job_comment_id user_id)a

  @type t :: %JobCommentLike{}
  schema "jobs_comments_likes" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:job_comment, JobComment, foreign_key: :job_comment_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%JobCommentLike{} = job_comment_like, attrs) do
    job_comment_like
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:job_comment_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :jobs_comments_likes_user_id_job_comment_id_index)
  end
end
