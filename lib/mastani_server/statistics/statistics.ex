defmodule MastaniServer.Statistics do
  @moduledoc """
  The Statistics context.
  """

  alias MastaniServer.Statistics.Delegate.{
    Contribute,
    Throttle
  }

  defdelegate make_contribute(info), to: Contribute
  defdelegate list_contributes(info), to: Contribute
  defdelegate list_contributes_digest(community), to: Contribute

  defdelegate log_publish_action(user), to: Throttle
  defdelegate load_throttle_record(user), to: Throttle
  defdelegate mock_throttle_attr(scope, user, opt), to: Throttle
end
