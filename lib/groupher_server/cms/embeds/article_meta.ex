defmodule GroupherServer.CMS.Embeds.ArticleMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields ~w(is_edited is_comment_locked is_reported)a

  @default_meta %{
    is_edited: false,
    is_comment_locked: false,
    is_reported: false
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:is_edited, :boolean, default: false)
    field(:is_comment_locked, :boolean, default: false)
    field(:is_reported, :boolean, default: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
