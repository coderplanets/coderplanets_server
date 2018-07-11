defmodule MastaniServer.CMS.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Post, Author, PostComment, PostFavorite, PostStar, Tag, Community}
  # alias MastaniServer.Accounts

  @required_fields ~w(title body digest length)a
  @optional_fields ~w(link_addr pin)

  schema "cms_posts" do
    field(:body, :string)
    field(:title, :string)
    field(:digest, :string)
    field(:link_addr, :string)
    field(:length, :integer)
    field(:views, :integer, default: 0)

    field(:pin, :boolean, default_value: false)
    belongs_to(:author, Author)

    # TODO
    # 相关文章
    # has_may(:related_post, ...)

    has_many(:comments, {"posts_comments", PostComment})
    has_many(:favorites, {"posts_favorites", PostFavorite})
    has_many(:stars, {"posts_stars", PostStar})
    # The keys are inflected from the schema names!
    # see https://hexdocs.pm/ecto/Ecto.Schema.html
    many_to_many(
      :tags,
      Tag,
      join_through: "posts_tags",
      join_keys: [post_id: :id, tag_id: :id],
      # :delete_all will only remove data from the join source
      on_delete: :delete_all,
      on_replace: :delete
    )

    many_to_many(
      :communities,
      Community,
      join_through: "communities_posts",
      on_replace: :delete
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)

    # |> foreign_key_constraint(:posts_tags, name: :posts_tags_tag_id_fkey)
    # |> foreign_key_constraint(name: :posts_tags_tag_id_fkey)
  end
end
