defmodule GroupherServer.CMS.Embeds.ArticleCommentMeta do
  @moduledoc """
  general article comment meta info
  """
  use Ecto.Schema

  alias CMS.Embeds

  @default_meta %{
    is_article_author_upvoted: false,
    is_solution: false,
    report_count: 0,
    report_users: []
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:is_article_author_upvoted, :boolean, default: false)
    field(:is_solution, :boolean, default: false)

    field(:report_count, :integer, default: 0)
    embeds_many(:report_users, Embeds.User, on_replace: :delete)
  end
end
