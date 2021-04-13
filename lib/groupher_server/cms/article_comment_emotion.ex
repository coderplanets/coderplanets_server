defmodule GroupherServer.CMS.ArticleCommentEmotion do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.Accounts.User
  alias GroupherServer.CMS.Embeds

  @default_emotions %{
    downvote_count: 0,
    downvote_users: [],
    tada_count: 0
    # tada_users: []
  }

  @doc "for test usage"
  def default_emotions(), do: @default_emotions

  embedded_schema do
    field(:downvote_count, :integer, default: 0)
    embeds_many(:downvote_users, Embeds.User, on_replace: :delete)

    field(:tada_count, :integer, default: 0)
    # embeds_many(:tada_users, User, on_replace: :delete)
    # embeds_many(:tada_users, User)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:downvote_count, :tada_count])
    # |> cast_embed(:downvote_users, required: false, with: &User.changeset/2)
    |> cast_embed(:downvote_users, required: false, with: &user_changeset/2)

    # |> cast_embed(:downvote_users, required: false, with: &User.changeset/2)

    # |> cast_embed(:tada_users, required: false, with: &User.changeset/2)

    # |> validate_required([:downvote_count, :tada_count])
  end

  defp user_changeset(struct, params) do
    struct
    |> cast(params, [:id, :nickname])
  end
end
