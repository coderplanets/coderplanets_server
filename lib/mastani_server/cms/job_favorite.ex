defmodule MastaniServer.CMS.JobFavorite do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Job, JobFavorite}
  alias MastaniServer.Accounts

  @required_fields ~w(user_id job_id)a

  schema "jobs_favorites" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:job, Job, foreign_key: :job_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%JobFavorite{} = job_favorite, attrs) do
    job_favorite
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :jobs_favorites_user_id_job_id_index)
  end
end
