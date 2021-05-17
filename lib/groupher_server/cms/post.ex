defmodule GroupherServer.CMS.Post do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.{Embeds, Author, Community, PostComment, Tag}

  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(title body digest length)a
  @article_comment_fields ~w(article_comments_count article_comments_participators_count)a
  @upvote_and_collect_fields ~w(upvotes_count collects_count)a
  @optional_fields ~w(original_community_id link_addr copy_right link_addr link_icon mark_delete)a ++
                     @article_comment_fields ++ @upvote_and_collect_fields

  @type t :: %Post{}
  schema "cms_posts" do
    field(:body, :string)
    field(:title, :string)
    field(:digest, :string)
    field(:link_addr, :string)
    field(:link_icon, :string)
    field(:copy_right, :string)
    field(:length, :integer)
    # field(:views, :integer, default: 0)

    # general_article_fields
    # - author_field
    # - article_comment_fields
    # - aritle_meta_field
    # - pin
    # - mark_delete
    # - emotion
    # - upvote_and_collect_fields
    # - viewer_has_fields
    # - timestamp

    # belongs_to(:author, Author)
    # embeds_one(:meta, Embeds.ArticleMeta, on_replace: :update)

    # field(:is_pinned, :boolean, default: false, virtual: true)
    # field(:mark_delete, :boolean, default: false)

    # TODO: remove after legacy data migrated
    has_many(:comments, {"posts_comments", PostComment})

    # embeds_one(:emotions, Embeds.ArticleEmotion, on_replace: :update)
    # belongs_to(:original_community, Community)

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

    general_article_fields()

    # timestamps(type: :utc_datetime)
    # for paged test to diff
    # timestamps(type: :utc_datetime_usec)
    # timestamps()
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

  defp generl_changeset(changeset) do
    changeset
    |> validate_length(:title, min: 3, max: 50)
    |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
    |> validate_length(:body, min: 3, max: 10_000)
    |> validate_length(:link_addr, min: 5, max: 400)
    |> HTML.safe_string(:body)
  end
end
