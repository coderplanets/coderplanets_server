defmodule GroupherServer.CMS.Helper.Macros do
  @moduledoc """
  macros for define article related fields in CMS models
  """
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Accounts}

  alias Accounts.User
  alias CMS.{Author, Community, ArticleComment, ArticleUpvote, ArticleCollect}

  @article_threads get_config(:article, :article_threads)

  @doc """
  generate belongs to fields for given thread

  e.g:
  belongs_to(:post, Post, foreign_key: :post_id)

  MIGRATION:
  should do migration to DB manually:
  数据库层面的 migration 需要手动添加，参考：

  add(:post_id, references(:cms_posts, on_delete: :delete_all))
  add(:job_id, references(:cms_jobs, on_delete: :delete_all))
  add(:repo_id, references(:cms_jobs, on_delete: :delete_all))
  ...
  """
  defmacro article_belongs_to_fields() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        belongs_to(
          unquote(thread),
          Module.concat(CMS, unquote(thread) |> to_string |> Recase.to_pascal()),
          foreign_key: unquote(:"#{thread}_id")
        )
      end
    end)
  end

  @doc """
  for GroupherServer.CMS.[Article]
  article_comments related fields

  MIGRATION:
  should do migration to DB manually:
  数据库层面的 migration 需要手动添加，参考：

  TABLE: "article_comments"
  -----
  add(:[article]_id, references(:cms_[article]s, on_delete: :delete_all))

  TABLE: "cms_[article]s"
  -----
  add(:article_comments_participators_count, :integer, default: 0)
  add(:article_comments_count, :integer, default: 0)
  add(:article_comments_participators, :map)
  """
  defmacro article_comment_fields() do
    quote do
      field(:article_comments_participators_count, :integer, default: 0)
      field(:article_comments_count, :integer, default: 0)
      has_many(:article_comments, {"articles_comments", ArticleComment})
      # 评论参与者，只保留最近 5 个
      embeds_many(:article_comments_participators, User, on_replace: :delete)
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
  def general_article_fields(:cast) do
    [
      :original_community_id,
      :article_comments_count,
      :article_comments_participators_count,
      :upvotes_count,
      :collects_count,
      :mark_delete
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

  # for :article_comment
  add(:article_comments_participators_count, :integer, default: 0)
  add(:article_comments_count, :integer, default: 0)
  add(:article_comments_participators, :map)

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
  defmacro general_article_fields do
    quote do
      belongs_to(:author, Author)

      field(:views, :integer, default: 0)
      field(:is_pinned, :boolean, default: false, virtual: true)
      field(:mark_delete, :boolean, default: false)

      embeds_one(:meta, CMS.Embeds.ArticleMeta, on_replace: :update)
      embeds_one(:emotions, CMS.Embeds.ArticleEmotion, on_replace: :update)

      belongs_to(:original_community, CMS.Community)

      upvote_and_collect_fields()
      viewer_has_fields()
      article_comment_fields()

      # TODO:
      # reference_articles
      # related_articles
      timestamps()
    end
  end

  @doc """
  for GroupherServer.CMS.Community

  # TABLE: "communities_[article]s"
    add(:community_id, references(:communities, on_delete: :delete_all), null: false)
    add(:[article]_id, references(:cms_[article]s, on_delete: :delete_all), null: false)

  create(unique_index(:communities_[article]s, [:community_id, :[article]_id]))
  """
  defmacro community_article_fields() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        many_to_many(
          unquote(:"#{thread}s"),
          Module.concat(CMS, unquote(thread) |> to_string |> Recase.to_pascal()),
          join_through: unquote("communities_#{to_string(thread)}s"),
          join_keys: [community_id: :id] ++ Keyword.new([{unquote(:"#{thread}_id"), :id}])
        )
      end
    end)
  end

  @doc """
  for GroupherServer.CMS.[Article]

  # TABLE: "communities_[article]s"
    add(:community_id, references(:communities, on_delete: :delete_all), null: false)
    add(:[article]_id, references(:cms_[article]s, on_delete: :delete_all), null: false)

  create(unique_index(:communities_[article]s, [:community_id, :[article]_id]))
  """
  defmacro article_community_field(thread) do
    quote do
      many_to_many(
        :communities,
        Community,
        join_through: unquote("communities_#{to_string(thread)}s"),
        on_replace: :delete
      )
    end
  end
end
