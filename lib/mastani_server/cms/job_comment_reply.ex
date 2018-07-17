defmodule MastaniServer.CMS.JobCommentReply do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.JobComment

  @required_fields ~w(job_comment_id reply_id)a

  @type t :: %JobCommentReply{}
  schema "jobs_comments_replies" do
    belongs_to(:job_comment, JobComment, foreign_key: :job_comment_id)
    belongs_to(:reply, JobComment, foreign_key: :reply_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%JobCommentReply{} = job_comment_reply, attrs) do
    job_comment_reply
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:job_comment_id)
    |> foreign_key_constraint(:reply_id)
  end
end
