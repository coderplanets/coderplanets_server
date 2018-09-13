defmodule MastaniServer.CMS.JobCommunityFlag do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias Helper.Certification
  alias MastaniServer.Accounts
  alias MastaniServer.CMS.{Community, Job}

  @required_fields ~w(job_id community_id)a
  @optional_fields ~w(pin trash)a

  @type t :: %JobCommunityFlag{}

  schema "jobs_communities_flags" do
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    field(:pin, :boolean)
    field(:trash, :boolean)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%JobCommunityFlag{} = job_community_flag, attrs) do
    job_community_flag
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:job_id, name: :jobs_communities_flags_job_id_community_id_index)
  end
end
