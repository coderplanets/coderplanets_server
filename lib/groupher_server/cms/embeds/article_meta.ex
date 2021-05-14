defmodule GroupherServer.CMS.Embeds.ArticleMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  alias GroupherServer.CMS

  @optional_fields ~w(is_edited is_comment_locked upvoted_user_ids collected_user_ids viewed_user_ids reported_user_ids reported_count)a

  @default_meta %{
    is_edited: false,
    is_comment_locked: false,
    upvoted_user_ids: [],
    collected_user_ids: [],
    viewed_user_ids: [],
    reported_user_ids: [],
    reported_count: 0
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:is_edited, :boolean, default: false)
    field(:is_comment_locked, :boolean, default: false)
    # reaction history
    field(:upvoted_user_ids, {:array, :integer}, default: [])
    field(:collected_user_ids, {:array, :integer}, default: [])
    field(:viewed_user_ids, {:array, :integer}, default: [])
    field(:reported_user_ids, {:array, :integer}, default: [])
    field(:reported_count, :integer, default: 0)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
