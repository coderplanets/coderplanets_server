defmodule GroupherServer.CMS.AbuseReport do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}
  alias CMS.{ArticleComment, Embeds, Post, Job}

  # @required_fields ~w(article_comment_id user_id recived_user_id)a
  @optional_fields ~w(article_comment_id post_id job_id account_id operate_user_id deal_with is_closed)a

  @type t :: %AbuseReport{}
  schema "abuse_reports" do
    belongs_to(:article_comment, ArticleComment, foreign_key: :article_comment_id)
    belongs_to(:post, Post, foreign_key: :post_id)
    belongs_to(:job, Job, foreign_key: :job_id)
    belongs_to(:account, Accounts.User, foreign_key: :account_id)

    embeds_many(:report_cases, Embeds.AbuseReportCase, on_replace: :delete)
    field(:report_cases_count, :integer, default: 0)

    belongs_to(:operate_user, Accounts.User, foreign_key: :operate_user_id)

    field(:deal_with, :string)
    field(:is_closed, :boolean, default: false)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%AbuseReport{} = struct, attrs) do
    struct
    |> cast(attrs, @optional_fields)
    |> cast_embed(:report_cases, required: true, with: &Embeds.AbuseReportCase.changeset/2)
  end
end
