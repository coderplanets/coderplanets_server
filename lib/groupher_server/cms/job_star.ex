defmodule GroupherServer.CMS.JobStar do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.Job

  @required_fields ~w(user_id job_id)a

  @type t :: %JobStar{}
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
