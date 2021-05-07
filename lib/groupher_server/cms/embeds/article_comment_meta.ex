defmodule GroupherServer.CMS.Embeds.ArticleCommentMeta do
  @moduledoc """
  general article comment meta info
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  @optional_fields ~w(is_article_author_upvoted is_solution report_count is_reply_to_others)a

  @default_meta %{
    is_article_author_upvoted: false,
    is_solution: false,
    is_reply_to_others: false,
    report_count: 0,
    upvoted_user_ids: []
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:is_article_author_upvoted, :boolean, default: false)
    field(:is_solution, :boolean, default: false)
    # used in replies mode, for those reply to other user in replies box (for frontend)
    # 用于回复模式，指代这条回复是回复“回复列表其他人的” （方便前端展示）
    field(:is_reply_to_others, :boolean, default: false)
    field(:report_count, :integer, default: 0)

    field(:upvoted_user_ids, {:array, :integer}, default: [])
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
