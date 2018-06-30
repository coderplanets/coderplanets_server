defmodule MastaniServerWeb.Middleware.PublishThrottle do
  @behaviour Absinthe.Middleware
  import Helper.Utils, only: [handle_absinthe_error: 3, get_config: 2]
  import Helper.ErrorCode

  alias MastaniServer.{Statistics, Accounts}
  alias Helper.ORM

  @interval_minutes get_config(:general, :publish_throttle_interval_minutes)
  @hour_total get_config(:general, :publish_throttle_hour_total)
  @day_total get_config(:general, :publish_throttle_day_total)

  def call(%{context: %{cur_user: cur_user}} = resolution, _info) do
    with {:ok, record} <- Statistics.load_throttle_record(%Accounts.User{id: cur_user.id}),
         {:ok, _} <- interval_check(record),
         {:ok, _} <- hour_limit_check(record),
         {:ok, _} <- day_limit_check(record) do
      resolution
    else
      {:error, :interval_check} ->
        resolution
        |> handle_absinthe_error("throttle_interval", ecode(:throttle_inverval))

      {:error, :hour_limit_check} ->
        resolution
        |> handle_absinthe_error("throttle_hour", ecode(:throttle_hour))

      {:error, :day_limit_check} ->
        resolution
        |> handle_absinthe_error("throttle_day", ecode(:throttle_day))

      {:error, error} ->
        resolution
    end
  end

  def call(resolution, _) do
    resolution
    |> handle_absinthe_error("Authorize: need login", ecode(:account_login))
  end

  # TODO: option: :no_limit :passport ..
  defp interval_check(%Statistics.PublishThrottle{last_publish_time: last_publish_time}) do
    latest_valid_time = Timex.shift(last_publish_time, minutes: @interval_minutes)

    case Timex.before?(latest_valid_time, Timex.now()) do
      true -> {:ok, :interval_check}
      false -> {:error, :interval_check}
    end
  end

  defp hour_limit_check(%Statistics.PublishThrottle{hour_count: hour_count}) do
    case hour_count < @hour_total do
      true -> {:ok, :hour_limit_check}
      false -> {:error, :hour_limit_check}
    end
  end

  defp day_limit_check(%Statistics.PublishThrottle{date_count: day_count}) do
    case day_count < @day_total do
      true -> {:ok, :day_limit_check}
      false -> {:error, :day_limit_check}
    end
  end
end
