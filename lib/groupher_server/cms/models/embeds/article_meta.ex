defmodule GroupherServer.CMS.Model.Embeds.ArticleMeta do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  alias GroupherServer.CMS.Model.Embeds

  @optional_fields ~w(thread is_edited is_comment_locked upvoted_user_ids collected_user_ids viewed_user_ids comments_participant_user_ids reported_user_ids reported_count is_sinked can_undo_sink last_active_at is_legal illegal_reason illegal_words)a

  @doc "for test usage"
  def default_meta() do
    %{
      thread: "POST",
      is_edited: false,
      is_comment_locked: false,
      folded_comment_count: 0,
      upvoted_user_ids: [],
      collected_user_ids: [],
      viewed_user_ids: [],
      reported_user_ids: [],
      comments_participant_user_ids: [],
      reported_count: 0,
      is_sinked: false,
      can_undo_sink: true,
      last_active_at: nil,
      citing_count: 0,
      latest_upvoted_users: [],
      latest_collected_users: [],
      # audit state
      is_legal: true,
      illegal_reason: [],
      illegal_words: []
    }
  end

  embedded_schema do
    field(:thread, :string)
    field(:is_edited, :boolean, default: false)
    field(:is_comment_locked, :boolean, default: false)
    field(:folded_comment_count, :integer, default: 0)

    # reaction history
    field(:upvoted_user_ids, {:array, :integer}, default: [])
    field(:collected_user_ids, {:array, :integer}, default: [])
    field(:viewed_user_ids, {:array, :integer}, default: [])
    field(:reported_user_ids, {:array, :integer}, default: [])
    field(:reported_count, :integer, default: 0)

    field(:comments_participant_user_ids, {:array, :integer}, default: [])

    field(:is_sinked, :boolean, default: false)
    field(:can_undo_sink, :boolean, default: false)
    # if undo_sink, can recover last active_at from here
    field(:last_active_at, :utc_datetime_usec)
    field(:citing_count, :integer, default: 0)

    embeds_many(:latest_upvoted_users, Embeds.User, on_replace: :delete)
    embeds_many(:latest_collected_users, Embeds.User, on_replace: :delete)

    # audit state
    field(:is_legal, :boolean, default: true)
    field(:illegal_reason, {:array, :string}, default: [])
    field(:illegal_words, {:array, :string}, default: [])
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
