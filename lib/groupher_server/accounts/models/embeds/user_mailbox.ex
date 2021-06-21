defmodule GroupherServer.Accounts.Model.Embeds.UserMailbox do
  @moduledoc """
  general article meta info for articles
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  @optional_fields ~w(reported_count)a

  embedded_schema do
    field(:is_empty, :boolean, default: false)
    field(:unread_total_count, :integer, default: 0)
    field(:unread_mentions_count, :integer, default: 0)
    field(:unread_notifications_count, :integer, default: 0)
  end

  def changeset(struct, params) do
    struct |> cast(params, @optional_fields)
  end
end
