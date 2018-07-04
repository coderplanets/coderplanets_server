defmodule MastaniServer.Delivery do
  @moduledoc """
  The Delivery context.
  """
  alias MastaniServer.Delivery.Delegate.Mentions
  # alias MastaniServer.Delivery.Delegate.{Mentions}

  defdelegate mention_someone(from_user, to_user, info), to: Mentions
  defdelegate fetch_mentions(user, filter), to: Mentions
  defdelegate mark_read_all(user, opt), to: Mentions

  alias MastaniServer.Delivery.Record
  alias MastaniServer.Accounts.User
  alias Helper.ORM

  def fetch_record(%User{id: user_id}) do
    Record |> ORM.find_by(user_id: user_id)
  end
end
