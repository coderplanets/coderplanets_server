defmodule GroupherServer.CMS.Model.CommunitySubscriber do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.Community

  @required_fields ~w(user_id community_id)a

  @type t :: %CommunitySubscriber{}
  schema "communities_subscribers" do
    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommunitySubscriber{} = community_subscriber, attrs) do
    community_subscriber
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :communities_subscribers_user_id_community_id_index)
  end
end
