defmodule MastaniServer.CMS.PostTag do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Post, PostTag}
  alias MastaniServer.Accounts

  @required_fields ~w(title user_id)a

  schema "post_tags" do
    field(:title, :string)
    belongs_to(:user, Accounts.User)

    many_to_many(
      :posts,
      Post,
      join_through: "posts_join_tags",
      join_keys: [post_id: :id, tag_id: :id]
    )

    timestamps()
  end

  def changeset(%PostTag{} = post_tag, attrs) do
    post_tag
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:title)
  end
end
