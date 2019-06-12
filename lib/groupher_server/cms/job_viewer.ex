defmodule GroupherServer.CMS.JobViewer do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.Accounts
  alias GroupherServer.CMS.Job

  @required_fields ~w(job_id user_id)a

  @type t :: %JobViewer{}
  schema "jobs_viewers" do
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:user, Accounts.User, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%JobViewer{} = job_viewer, attrs) do
    job_viewer
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :jobs_viewers_job_id_user_id_index)
  end
end
