defmodule GroupherServer.CMS.Embeds.ArticleCommentMeta do
  @moduledoc """
  general article comment meta info
  """
  use Ecto.Schema

  alias CMS.Embeds

  @default_meta %{
    report_count: 0,
    report_users: []
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:report_count, :integer, default: 0)
    embeds_many(:report_users, Embeds.User, on_replace: :delete)
  end
end
