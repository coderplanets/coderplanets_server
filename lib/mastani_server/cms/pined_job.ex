defmodule MastaniServer.CMS.PinedJob do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Community, Job}

  @required_fields ~w(job_id community_id)a

  @type t :: %PinedJob{}
  schema "pined_jobs" do
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PinedJob{} = pined_job, attrs) do
    pined_job
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:pined_jobs, name: :pined_jobs_job_id_community_id_index)
  end
end
