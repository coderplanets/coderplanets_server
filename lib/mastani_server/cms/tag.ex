defmodule MastaniServer.CMS.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Author, Post, Tag, Community}
  alias MastaniServer.Accounts

  @required_fields ~w(part title color author_id community_id)a

  schema "tags" do
    field(:title, :string)
    field(:color, :string)
    field(:part, :string)
    belongs_to(:community, Community)
    # belongs_to(:user, Accounts.User)
    belongs_to(:author, Author)

    many_to_many(
      :posts,
      Post,
      join_through: "posts_join_tags",
      join_keys: [post_id: :id, tag_id: :id]
    )

    timestamps(type: :utc_datetime)
  end

  def changeset(%Tag{} = tag, attrs) do
    tag
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint(:tag_in_community, name: :tags_community_id_part_title_index)

    # |> unique_constraint(:user_id, name: :posts_favorites_user_id_post_id_index)
    # |> unique_constraint(:title)
  end
end
