defmodule GroupherServer.Statistics.Model.CommunityContribute do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.CMS.Model.Community

  @type t :: %CommunityContribute{}
  schema "community_contributes" do
    field(:count, :integer)
    field(:date, :date)
    # field(:community_id, :id)
    belongs_to(:community, Community)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommunityContribute{} = community_contribute, attrs) do
    community_contribute
    |> cast(attrs, [:date, :count, :community_id])
    |> validate_required([:date, :count, :community_id])
    |> foreign_key_constraint(:community_id)

    # |> unique_constraint(:community_id, name: :communities_threads_community_id_thread_id_index)
  end
end
