defmodule GroupherServer.CMS.Job do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.{CMS, Accounts}

  alias CMS.{
    Author,
    Embeds,
    ArticleComment,
    Community,
    JobCommunityFlag,
    Tag,
    ArticleUpvote,
    ArticleCollect
  }

  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]
  @required_fields ~w(title company company_logo body digest length)a
  @optional_fields ~w(origial_community_id desc company_link link_addr copy_right salary exp education field finance scale article_comments_count article_comments_participators_count upvotes_count collects_count)a

  @type t :: %Job{}
  schema "cms_jobs" do
    field(:title, :string)
    field(:company, :string)
    field(:company_logo, :string)
    field(:company_link, :string)
    field(:desc, :string)
    field(:body, :string)
    belongs_to(:author, Author)
    field(:views, :integer, default: 0)

    embeds_one(:meta, Embeds.ArticleMeta, on_replace: :update)

    field(:link_addr, :string)
    field(:copy_right, :string)

    field(:salary, :string)
    field(:exp, :string)
    field(:education, :string)
    field(:field, :string)
    field(:finance, :string)
    field(:scale, :string)

    field(:digest, :string)
    field(:length, :integer)

    has_many(:community_flags, {"jobs_communities_flags", JobCommunityFlag})

    # NOTE: this one is tricky, pin is dynamic changed when return by func: add_pin_contents_ifneed
    field(:is_pinned, :boolean, default: false, virtual: true)
    field(:trash, :boolean, default_value: false, virtual: true)

    has_many(:upvotes, {"article_upvotes", ArticleUpvote})
    field(:upvotes_count, :integer, default: 0)

    has_many(:collects, {"article_collects", ArticleCollect})
    field(:collects_count, :integer, default: 0)

    has_many(:article_comments, {"articles_comments", ArticleComment})
    field(:article_comments_count, :integer, default: 0)
    field(:article_comments_participators_count, :integer, default: 0)
    # 评论参与者，只保留最近 5 个
    embeds_many(:article_comments_participators, Accounts.User, on_replace: :delete)

    embeds_one(:emotions, Embeds.ArticleEmotion, on_replace: :update)

    many_to_many(
      :tags,
      Tag,
      join_through: "jobs_tags",
      join_keys: [job_id: :id, tag_id: :id],
      # :delete_all will only remove data from the join source
      on_delete: :delete_all,
      on_replace: :delete
    )

    belongs_to(:origial_community, Community)

    many_to_many(
      :communities,
      Community,
      join_through: "communities_jobs",
      on_replace: :delete
    )

    # timestamps(type: :utc_datetime)
    timestamps()
  end

  @doc false
  def changeset(%Job{} = job, attrs) do
    job
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Job{} = job, attrs) do
    job
    |> cast(attrs, @optional_fields ++ @required_fields)
    # |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  defp generl_changeset(content) do
    content
    |> validate_length(:title, min: 3, max: 50)
    |> validate_length(:body, min: 3, max: 10_000)
    # |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
    |> HTML.safe_string(:body)
  end
end
