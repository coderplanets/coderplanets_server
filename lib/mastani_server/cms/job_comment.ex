defmodule MastaniServer.CMS.JobComment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.Accounts

  alias MastaniServer.CMS.{Job, JobCommentReply}

  @required_fields ~w(body author_id job_id floor)a
  @optional_fields ~w(reply_id)a

  @type t :: %JobComment{}
  schema "jobs_comments" do
    field(:body, :string)
    field(:floor, :integer)
    belongs_to(:author, Accounts.User, foreign_key: :author_id)
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:reply_to, JobComment, foreign_key: :reply_id)
    # belongs_to(:reply_to, JobComment, foreign_key: :job_id)
    has_many(:replies, {"jobs_comments_replies", JobCommentReply})
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%JobComment{} = job_comment, attrs) do
    job_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:author_id)
  end
end
