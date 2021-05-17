defmodule GroupherServer.CMS.Helper.Macros do
  @moduledoc """
  macros for define article related fields in CMS models
  """

  alias GroupherServer.{CMS, Accounts}

  alias Accounts.User
  alias CMS.{Community, ArticleComment, ArticleUpvote, ArticleCollect}

  @article_threads Community.article_threads()

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
  aritlce's upvote and collect feature

  MIGRATION:
  should do migration to DB manually:
  数据库层面的 migration 需要手动添加，参考：

  TABLE: "cms_[article]s"
  -----
  add(:upvotes_count, :integer, default: 0)
  add(:collects_count, :integer, default: 0)
  """
  defmacro upvote_and_collect_fields() do
    quote do
      has_many(:upvotes, {"article_upvotes", ArticleUpvote})
      field(:upvotes_count, :integer, default: 0)

      has_many(:collects, {"article_collects", ArticleCollect})
      field(:collects_count, :integer, default: 0)
    end
  end

  defmacro general_article_fields do
    quote do
      field(:views, :integer, default: 0)
      field(:is_pinned, :boolean, default: false, virtual: true)
      field(:mark_delete, :boolean, default: false)

      embeds_one(:meta, CMS.Embeds.ArticleMeta, on_replace: :update)
      belongs_to(:original_community, CMS.Community)
      embeds_one(:emotions, CMS.Embeds.ArticleEmotion, on_replace: :update)

      upvote_and_collect_fields()
      viewer_has_fields()
      article_comment_fields()
      timestamps()
    end
  end

  # TODO:
  # reference_articles
  # related_articles
end
