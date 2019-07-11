defmodule GroupherServer.CMS.PostCommunityFlag do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.CMS
  alias CMS.{Community, Post}

  @required_fields ~w(post_id community_id)a
  @optional_fields ~w(trash)a

  @type t :: %PostCommunityFlag{}

  schema "posts_communities_flags" do
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    field(:trash, :boolean)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PostCommunityFlag{} = post_community_flag, attrs) do
    post_community_flag
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:post_id, name: :posts_communities_flags_post_id_community_id_index)
  end
end
