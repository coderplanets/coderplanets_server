defmodule GroupherServer.CMS.Model.CommunityThread do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.Model.{Community, Thread}

  @required_fields ~w(community_id thread_id)a

  @type t :: %CommunityThread{}
  schema "communities_threads" do
    belongs_to(:community, Community, foreign_key: :community_id)
    belongs_to(:thread, Thread, foreign_key: :thread_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommunityThread{} = community_thread, attrs) do
    community_thread
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:thread_id)
    |> unique_constraint(:community_id, name: :communities_threads_community_id_thread_id_index)
  end
end
