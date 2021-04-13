defmodule GroupherServer.CMS.ArticleCommentEmotion do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.Accounts.User

  @default_emotions %{
    downvote_count: 0,
    downvote_users: [],
    tada_count: 0,
    tada_users: []
  }

  @doc "for test usage"
  def default_emotions(), do: @default_emotions

  embedded_schema do
    field(:downvote_count, :integer, default: 0)
    embeds_many(:downvote_users, User, on_replace: :delete)

    field(:tada_count, :integer, default: 0)
    embeds_many(:tada_users, User, on_replace: :delete)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:downvote_count, :tada_count])
    |> validate_required([:downvote_count, :tada_count])
  end
end
