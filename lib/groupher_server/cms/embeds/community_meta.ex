defmodule GroupherServer.CMS.Embeds.CommunityMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  @optional_fields ~w(articles_count posts_count jobs_count repos_count subscribers_count subscribed_user_ids editors_count contributes_digest)a

  @default_meta %{
    articles_count: 0,
    posts_count: 0,
    jobs_count: 0,
    repos_count: 0,
    subscribers_count: 0,
    subscribed_user_ids: [],
    editors_count: 0,
    contributes_digest: []
  }

  @doc "for test usage"
  def default_meta(), do: @default_meta

  embedded_schema do
    field(:articles_count, :integer, default: 0)
    # TODO: use macros to extract
    field(:posts_count, :integer, default: 0)
    field(:jobs_count, :integer, default: 0)
    field(:repos_count, :integer, default: 0)

    # 关注相关
    field(:subscribers_count, :integer, default: 0)
    field(:subscribed_user_ids, {:array, :integer}, default: [])

    field(:editors_count, :integer, default: 0)
    field(:contributes_digest, {:array, :integer}, default: [])
  end

  def changeset(struct, params) do
    struct |> cast(params, @optional_fields)
  end
end
