defmodule MastaniServer.CMS.JobStar do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Job, JobStar}
  alias MastaniServer.Accounts

  @required_fields ~w(user_id job_id)a

  schema "jobs_stars" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:job, Job, foreign_key: :job_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%JobStar{} = job_star, attrs) do
    # |> unique_constraint(:user_id, name: :favorites_user_id_article_id_index)
    job_star
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :jobs_stars_user_id_job_id_index)
  end
end
