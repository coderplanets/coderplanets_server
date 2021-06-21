defmodule GroupherServer.Delivery do
  @moduledoc """
  The Delivery context.
  """

  alias GroupherServer.Delivery
  alias Delivery.Delegate.Postman

  defdelegate send(service, artiment, mentions, from_user), to: Postman
  defdelegate send(service, attrs, from_user), to: Postman
  defdelegate revoke(service, attrs, from_user), to: Postman
  defdelegate fetch(service, user, filter), to: Postman
  defdelegate unread_count(service, user), to: Postman

  defdelegate mark_read(service, ids, user), to: Postman
  defdelegate mark_read_all(service, user), to: Postman
end
