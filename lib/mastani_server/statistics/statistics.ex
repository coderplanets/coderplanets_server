defmodule MastaniServer.Statistics do
  @moduledoc """
  The Statistics context.
  """

  alias MastaniServer.Statistics.Delegate.{
    Contribute,
    Throttle,
    Geo
  }

  # contributes
  defdelegate make_contribute(info), to: Contribute
  defdelegate list_contributes(info), to: Contribute
  defdelegate list_contributes_digest(community), to: Contribute

  # publish Throttle
  defdelegate log_publish_action(user), to: Throttle
  defdelegate load_throttle_record(user), to: Throttle
  defdelegate mock_throttle_attr(scope, user, opt), to: Throttle

  # geo
  defdelegate inc_count(city), to: Geo
  defdelegate list_cities_info(), to: Geo
end
