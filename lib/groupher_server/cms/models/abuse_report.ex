defmodule GroupherServer.CMS.Model.AbuseReport do
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
  alias CMS.Model.{Comment, Embeds}

  @article_threads get_config(:article, :threads)

  # @required_fields ~w(comment_id user_id recived_user_id)a
  @optional_fields ~w(comment_id account_id operate_user_id deal_with report_cases_count)a
  @update_fields ~w(operate_user_id deal_with report_cases_count)a

  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @type t :: %AbuseReport{}
  schema "abuse_reports" do
    belongs_to(:comment, Comment, foreign_key: :comment_id)
    belongs_to(:account, User, foreign_key: :account_id)

    embeds_many(:report_cases, Embeds.AbuseReportCase, on_replace: :delete)
    field(:report_cases_count, :integer, default: 0)

    belongs_to(:operate_user, User, foreign_key: :operate_user_id)

    field(:deal_with, :string)

    article_belongs_to_fields()
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%AbuseReport{} = struct, attrs) do
    struct
    |> cast(attrs, @optional_fields ++ @article_fields)
    |> cast_embed(:report_cases, required: true, with: &Embeds.AbuseReportCase.changeset/2)
    |> articles_foreign_key_constraint
  end

  def update_changeset(%AbuseReport{} = struct, attrs) do
    struct
    |> cast(attrs, @update_fields ++ @article_fields)
    |> cast_embed(:report_cases, required: true, with: &Embeds.AbuseReportCase.changeset/2)
    |> articles_foreign_key_constraint
  end
end
