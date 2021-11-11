defmodule GroupherServer.CMS.Helper.Macros do
  @moduledoc """
  macros for define article related fields in CMS models
  """
  import Helper.Utils, only: [get_config: 2, plural: 1]

  alias GroupherServer.{CMS, Accounts}

  alias Accounts.Model.User
  alias CMS.Model.{Embeds, Author, Community, Comment, ArticleTag, ArticleUpvote, ArticleCollect}

  @article_threads get_config(:article, :threads)

  @doc """
  generate belongs to fields for given thread

  e.g:
  belongs_to(:post, Post, foreign_key: :post_id)

  MIGRATION:
  should do migration to DB manually:
  数据库层面的 migration 需要手动添加，参考：

  add(:post_id, references(:cms_posts, on_delete: :delete_all))
  add(:job_id, references(:cms_jobs, on_delete: :delete_all))
  add(:repo_id, references(:cms_repos, on_delete: :delete_all))
  ...
  """
  defmacro article_belongs_to_fields() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        belongs_to(
          unquote(thread),
          Module.concat(CMS.Model, Recase.to_pascal(to_string(unquote(thread)))),
          foreign_key: unquote(:"#{thread}_id")
        )
      end
    end)
  end

  @doc """
  for GroupherServer.CMS.[Article]
  comments related fields

  MIGRATION:
  should do migration to DB manually:
  数据库层面的 migration 需要手动添加，参考：

  TABLE: "comments"
  -----
  add(:[article]_id, references(:cms_[article]s, on_delete: :delete_all))

  TABLE: "cms_[article]s"
  -----
  add(:comments_participants_count, :integer, default: 0)
  add(:comments_count, :integer, default: 0)
  add(:comments_participants, :map)
  """
  defmacro comment_fields() do
    quote do
      field(:comments_participants_count, :integer, default: 0)
      field(:comments_count, :integer, default: 0)
      has_many(:comments, {"comments", Comment})
      # 评论参与者，只保留最近 5 个
      embeds_many(:comments_participants, User, on_replace: :delete)
    end
  end

  @doc """
  for GroupherServer.CMS.[Article]
  viewer has xxx fields for each article

  those fields is virtual, do not need DB migration
  """
  defmacro viewer_has_fields() do
    quote do
      field(:viewer_has_viewed, :boolean, default: false, virtual: true)
      field(:viewer_has_upvoted, :boolean, default: false, virtual: true)
      field(:viewer_has_collected, :boolean, default: false, virtual: true)
      field(:viewer_has_reported, :boolean, default: false, virtual: true)
    end
  end

  @doc """
  for GroupherServer.CMS.[Article]
  aritlce's upvote and collect feature

  MIGRATION:
  should do migration to DB manually:
  数据库层面的 migration 需要手动添加，参考：

  TABLE: "cms_[article]s"
  -----
  add(:upvotes_count, :integer, default: 0)
  add(:collects_count, :integer, default: 0)

  ## TABLE: "article_upvotes" and TABLE: "article_collects"
  -----
  add(:[article]_id, references(:cms_[article]s, on_delete: :delete_all))
  """
  defmacro upvote_and_collect_fields() do
    quote do
      has_many(:upvotes, {"article_upvotes", ArticleUpvote})
      field(:upvotes_count, :integer, default: 0)

      has_many(:collects, {"article_collects", ArticleCollect})
      field(:collects_count, :integer, default: 0)
    end
  end

  @doc """
  for GroupherServer.CMS.[Article]

  common casting fields for general_article_fields
  """
  def general_article_cast_fields() do
    [
      :title,
      :digest,
      :link_addr,
      :original_community_id,
      :comments_count,
      :comments_participants_count,
      :upvotes_count,
      :collects_count,
      :mark_delete,
      :active_at,
      :pending
    ]
  end

  @doc """
  for GroupherServer.CMS.[Article]

  MIGRATION:

  TABLE: "cms_[article]s"
  -----
  # for :author
  add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)
  create(index(:cms_[article]s, [:author_id]))

  # for :views
  add(:views, :integer, default: 0)

  # for :mark_delete
  add(:mark_delete, :boolean, default: false)

  # for :meta
  add(:meta, :map)

  # for :emotion
  add(:emotions, :map)

  # for :original_community
  add(:original_community_id, references(:communities, on_delete: :delete_all))

  # for :upvote and :collect
  add(:upvotes_count, :integer, default: 0)
  add(:collects_count, :integer, default: 0)

  # for :comment
  add(:comments_participants_count, :integer, default: 0)
  add(:comments_count, :integer, default: 0)
  add(:comments_participants, :map)

  # for table contains macro "article_belongs_to_fields":
  # TABLE: "abuse_reports"
  # TABLE: "article_collects"
  # TABLE: "article_upvotes"
  # TABLE: "articles_comments"
  # TABLE: "articles_pinned_comments"
  # TABLE: "articles_users_emotions"
  # TABLE: "pinned_articles"
  -----
  add(:[article]_id, references(:cms_[article]s, on_delete: :delete_all))

  """
  defmacro general_article_fields(thread) do
    quote do
      field(:title, :string)
      field(:digest, :string)

      field(:views, :integer, default: 0)
      field(:is_pinned, :boolean, default: false, virtual: true)
      field(:mark_delete, :boolean, default: false)

      belongs_to(:author, Author)

      field(:link_addr, :string)

      has_one(
        :document,
        unquote(Module.concat(CMS.Model, "#{Recase.to_title(to_string(thread))}Document"))
      )

      embeds_one(:meta, Embeds.ArticleMeta, on_replace: :update)
      embeds_one(:emotions, Embeds.ArticleEmotion, on_replace: :update)

      belongs_to(:original_community, Community)

      upvote_and_collect_fields()
      viewer_has_fields()
      comment_fields()

      field(:active_at, :utc_datetime_usec)

      field(:is_archived, :boolean)
      field(:archived_at, :utc_datetime_usec)

      field(:pending, :integer, default: 0)

      timestamps()
    end
  end

  @doc """
  for GroupherServer.CMS.[Article]

  # TABLE: "communities_join_[article]s"
  add(:community_id, references(:communities, on_delete: :delete_all), null: false)
  add(:[article]_id, references(:cms_[article]s, on_delete: :delete_all), null: false)

  create(unique_index(:communities_join_[article]s, [:community_id, :[article]_id]))
  """
  defmacro article_communities_field(thread) do
    quote do
      many_to_many(
        :communities,
        Community,
        join_through: unquote("communities_join_#{plural(thread)}"),
        on_replace: :delete
      )
    end
  end

  @doc """
  for GroupherServer.CMS.[Article]

  # TABLE: "articles_join_tags"

  add(:[article]_id, references(:cms_[article]s, on_delete: :delete_all))
  """
  defmacro article_tags_field(thread) do
    quote do
      many_to_many(
        :article_tags,
        ArticleTag,
        join_through: "articles_join_tags",
        join_keys: Keyword.new([{unquote(:"#{thread}_id"), :id}]) ++ [article_tag_id: :id],
        # :delete_all will only remove data from the join source
        on_delete: :delete_all,
        on_replace: :delete
      )
    end
  end
end
