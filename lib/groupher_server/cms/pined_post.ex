defmodule GroupherServer.CMS.PinedPost do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset
  alias GroupherServer.CMS.{Community, Post, Topic}

  @required_fields ~w(post_id community_id)a
  @optional_fields ~w(topic_id)a

  @type t :: %PinedPost{}
  schema "pined_posts" do
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:community, Community, foreign_key: :community_id)
    belongs_to(:topic, Topic, foreign_key: :topic_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PinedPost{} = pined_post, attrs) do
    pined_post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:pined_posts, name: :pined_posts_post_id_community_id_topic_id_index)
  end
end
