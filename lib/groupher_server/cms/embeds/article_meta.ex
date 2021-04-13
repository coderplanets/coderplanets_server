defmodule GroupherServer.CMS.Embeds.ArticleMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema

  @default_meta %{
    is_edited: false,
    forbid_comment: false,
    is_reported: false
    # linkedPostsCount: 0,
    # linkedJobsCount: 0,
    # linkedWorksCount: 0,
    # reaction: %{
    #   rocketCount: 0,
    #   heartCount: 0,
    # }
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:is_edited, :boolean, default: false)
    field(:forbid_comment, :boolean, default: false)
    field(:is_reported, :boolean, default: false)
  end
end
