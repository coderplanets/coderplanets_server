defmodule GroupherServer.CMS.Post do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.{CMS, Accounts}

  alias CMS.{
    Embeds,
    Author,
    ArticleComment,
    ArticlePinedComment,
    Community,
    PostComment,
    PostCommunityFlag,
    PostViewer,
    Tag,
    ArticleUpvote,
    ArticleCollect
  }

  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]
  @required_fields ~w(title body digest length)a
  @optional_fields ~w(origial_community_id link_addr copy_right link_addr link_icon article_comments_count article_comments_participators_count upvotes_count collects_count)a

  @type t :: %Post{}
  schema "cms_posts" do
    field(:body, :string)
    field(:title, :string)
    field(:digest, :string)
    field(:link_addr, :string)
    field(:link_icon, :string)
    field(:copy_right, :string)
    field(:length, :integer)
    field(:views, :integer, default: 0)

    embeds_one(:meta, Embeds.ArticleMeta, on_replace: :update)

    has_many(:community_flags, {"posts_communities_flags", PostCommunityFlag})

    # NOTE: this one is tricky, pin is dynamic changed when return by func: add_pin_contents_ifneed
    # field(:pin, :boolean, default_value: false, virtual: true)
    field(:is_pinned, :boolean, default: false, virtual: true)
    field(:trash, :boolean, default_value: false, virtual: true)

    belongs_to(:author, Author)

    # TODO
    # 相关文章
    # has_may(:related_post, ...)
    has_many(:comments, {"posts_comments", PostComment})

    has_many(:article_comments, {"articles_comments", ArticleComment})
    has_many(:article_pined_comments, {"articles_pined_comments", ArticlePinedComment})
    field(:article_comments_count, :integer, default: 0)
    field(:article_comments_participators_count, :integer, default: 0)
    # 评论参与者，只保留最近 5 个
    embeds_many(:article_comments_participators, Accounts.User, on_replace: :delete)

    has_many(:upvotes, {"article_upvotes", ArticleUpvote})
    field(:upvotes_count, :integer, default: 0)

    has_many(:collects, {"article_collects", ArticleCollect})
    field(:collects_count, :integer, default: 0)

    has_many(:viewers, {"posts_viewers", PostViewer})
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

    belongs_to(:origial_community, Community)

    many_to_many(
      :communities,
      Community,
      join_through: "communities_posts",
      on_replace: :delete
    )

    # timestamps(type: :utc_datetime)
    # for paged test to diff
    # timestamps(type: :utc_datetime_usec)
    timestamps()
  end

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> validate_length(:title, min: 3, max: 50)
    |> validate_length(:body, min: 3, max: 10_000)
    |> validate_length(:link_addr, min: 5, max: 400)
    |> HTML.safe_string(:body)

    # |> foreign_key_constraint(:posts_tags, name: :posts_tags_tag_id_fkey)
    # |> foreign_key_constraint(name: :posts_tags_tag_id_fkey)
  end
end
