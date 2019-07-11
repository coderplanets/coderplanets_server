defmodule GroupherServer.CMS.JobFavorite do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}
  alias CMS.Job

  @required_fields ~w(user_id job_id)a
  @optional_fields ~w(category_id)a

  @type t :: %JobFavorite{}
  schema "jobs_favorites" do
    belongs_to(:user, Accounts.User, foreign_key: :user_id)
    belongs_to(:job, Job, foreign_key: :job_id)

    belongs_to(:category, Accounts.FavoriteCategory)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%JobFavorite{} = job_favorite, attrs) do
    job_favorite
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:user_id, name: :jobs_favorites_user_id_job_id_index)
  end

  @doc false
  def update_changeset(%JobFavorite{} = job_favorite, attrs) do
    job_favorite
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> unique_constraint(:user_id, name: :jobs_favorites_user_id_job_id_index)
  end
end
