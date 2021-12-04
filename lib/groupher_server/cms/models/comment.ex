defmodule GroupherServer.CMS.Model.Comment do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]
  import GroupherServer.CMS.Helper.Macros
  import GroupherServer.CMS.Helper.Utils, only: [articles_foreign_key_constraint: 1]

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias CMS.Model.{Embeds, CommentUpvote}

  # alias Helper.HTML
  @article_threads get_config(:article, :threads)

  @required_fields ~w(body author_id)a
  @optional_fields ~w(body_html reply_to_id replies_count is_folded is_deleted floor is_article_author thread is_for_question is_solution pending)a
  # @updatable_fields ~w(body_html is_folded is_deleted floor upvotes_count is_pinned is_for_question is_solution replies_count pending)a
  @updatable_fields ~w(body_html is_folded is_deleted floor upvotes_count is_pinned is_for_question is_solution replies_count pending inserted_at updated_at is_archived archived_at is_article_author)a

  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @max_participator_count 5
  @max_parent_replies_count 3

  @max_latest_emotion_users_count 5

  @delete_hint "this comment is deleted"
  # 举报超过此数评论会被自动折叠
  @report_threshold_for_fold 5

  # 每篇文章最多含有置顶评论的条数
  @pinned_comment_limit 10

  @doc "latest participants stores in article comment_participants field"
  def max_participator_count(), do: @max_participator_count
  @doc "latest replies stores in comment replies field, used for frontend display"
  def max_parent_replies_count(), do: @max_parent_replies_count

  @doc "操作某 emotion 的最近用户"
  def max_latest_emotion_users_count(), do: @max_latest_emotion_users_count
  def delete_hint(), do: @delete_hint

  def report_threshold_for_fold, do: @report_threshold_for_fold
  def pinned_comment_limit, do: @pinned_comment_limit

  @type t :: %Comment{}
  schema "comments" do
    belongs_to(:author, User, foreign_key: :author_id)

    field(:thread, :string)
    field(:body, :string)
    field(:body_html, :string)
    # 是否被折叠
    field(:is_folded, :boolean, default: false)
    # 是否被删除
    field(:is_deleted, :boolean, default: false)
    # 楼层
    field(:floor, :integer, default: 0)

    field(:is_for_question, :boolean, default: false)
    field(:is_solution, :boolean, default: false)

    # 是否是评论文章的作者
    field(:is_article_author, :boolean, default: false)
    field(:upvotes_count, :integer, default: 0)

    # 是否置顶
    field(:is_pinned, :boolean, default: false)
    field(:viewer_has_upvoted, :boolean, default: false, virtual: true)
    field(:viewer_has_reported, :boolean, default: false, virtual: true)

    belongs_to(:reply_to, Comment, foreign_key: :reply_to_id)

    embeds_many(:replies, Comment, on_replace: :delete)
    field(:replies_count, :integer, default: 0)

    embeds_one(:emotions, Embeds.CommentEmotion, on_replace: :update)
    embeds_one(:meta, Embeds.CommentMeta, on_replace: :update)

    has_many(:upvotes, {"comments_upvotes", CommentUpvote})

    field(:is_archived, :boolean, default: false)
    field(:archived_at, :utc_datetime)

    field(:pending, :integer, default: 0)

    article_belongs_to_fields()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, @required_fields ++ @optional_fields ++ @article_fields)
    |> cast_embed(:emotions, required: true, with: &Embeds.CommentEmotion.changeset/2)
    |> cast_embed(:meta, required: true, with: &Embeds.CommentMeta.changeset/2)
    |> validate_required(@required_fields)
    |> generl_changeset
  end

  # @doc false
  def update_changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, @required_fields ++ @updatable_fields ++ @article_fields)
    |> cast_embed(:meta, required: true, with: &Embeds.CommentMeta.changeset/2)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> foreign_key_constraint(:author_id)
    |> articles_foreign_key_constraint

    # |> validate_length(:body_html, min: 3, max: 2000)
    # |> HTML.safe_string(:body_html)
  end
end
