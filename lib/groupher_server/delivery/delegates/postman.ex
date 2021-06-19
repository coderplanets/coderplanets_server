defmodule GroupherServer.Delivery.Delegate.Postman do
  @moduledoc """
  The Delivery context.
  """

  alias GroupherServer.Delivery.Delegate.Mention

  def send(:mention, artiment, mentions, from_user) do
    Mention.handle(artiment, mentions, from_user)
  end

  def fetch(:mention, user, filter) do
    Mention.paged_mentions(user, filter)
  end
end
