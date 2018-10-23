defmodule MastaniServer.CMS.Post do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias MastaniServer.CMS.{
    Author,
    Community,
    PostComment,
    PostCommunityFlag,
    PostFavorite,
    PostStar,
    Tag
  }

  @required_fields ~w(title body digest length)a
  @optional_fields ~w(link_addr copy_right)a

  @type t :: %Post{}
  schema "cms_posts" do
    field(:body, :string)
    field(:title, :string)
    field(:digest, :string)
    field(:link_addr, :string)
    field(:copy_right, :string)
    field(:length, :integer)
    field(:views, :integer, default: 0)

    has_many(:community_flags, {"posts_communities_flags", PostCommunityFlag})

    # NOTE: this one is tricky, pin is dynamic changed when return by func: add_pin_contents_ifneed
    field(:pin, :boolean, default_value: false, virtual: true)
    field(:trash, :boolean, default_value: false, virtual: true)

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

  @doc """
  for update flag
  """
  # def flag_changeset(%Post{} = post, attrs) do
  # post
  # |> cast(attrs, ~w(pin trash)a)
  # end
end
