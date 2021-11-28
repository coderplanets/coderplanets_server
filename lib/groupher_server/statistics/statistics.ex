defmodule GroupherServer.Statistics do
  @moduledoc """
  The Statistics context.
  """

  alias GroupherServer.Statistics.Delegate
  alias Delegate.{Contribute, Geo, Status, Throttle}

  # contributes
  defdelegate make_contribute(info), to: Contribute
  defdelegate list_contributes_digest(community), to: Contribute

  # publish Throttle
  defdelegate log_publish_action(user), to: Throttle
  defdelegate load_throttle_record(user), to: Throttle
  defdelegate mock_throttle_attr(scope, user, opt), to: Throttle

  # geo
  defdelegate inc_count(city), to: Geo
  defdelegate list_cities_info(), to: Geo

  # countStatus
  defdelegate count_status(), to: Status
  defdelegate online_status(), to: Status
end
