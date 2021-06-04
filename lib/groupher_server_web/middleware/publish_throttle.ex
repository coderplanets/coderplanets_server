defmodule GroupherServerWeb.Middleware.PublishThrottle do
  @moduledoc """
  throttle control for publish contents
  """

  @behaviour Absinthe.Middleware
  import Helper.Utils, only: [handle_absinthe_error: 3, get_config: 2]
  import Helper.ErrorCode

  alias GroupherServer.{Accounts, Statistics}
  alias Accounts.Model.User
  alias Statistics.Model.PublishThrottle

  @interval_minutes get_config(:general, :publish_throttle_interval_minutes)
  @hour_limit get_config(:general, :publish_throttle_hour_limit)
  @day_total get_config(:general, :publish_throttle_day_limit)

  def call(
        %{context: %{cur_user: %{cur_passport: %{"cms" => %{"root" => true}}}}} = resolution,
        _
      ) do
    resolution
  end

  def call(%{context: %{cur_user: cur_user}} = resolution, opt) do
    with {:ok, record} <- Statistics.load_throttle_record(%User{id: cur_user.id}),
         {:ok, _} <- interval_check(record, opt),
         {:ok, _} <- hour_limit_check(record, opt),
         {:ok, _} <- day_limit_check(record, opt) do
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

      {:error, _error} ->
        # publish first time ignore
        resolution
    end
  end

  def call(resolution, _) do
    resolution
    |> handle_absinthe_error("Authorize: need login", ecode(:account_login))
  end

  # TODO: option: passport ..
  defp interval_check(%PublishThrottle{last_publish_time: last_publish_time}, opt) do
    interval_opt = Keyword.get(opt, :interval) || @interval_minutes
    latest_valid_time = Timex.shift(last_publish_time, minutes: interval_opt)

    case Timex.before?(latest_valid_time, Timex.now()) do
      true -> {:ok, :interval_check}
      false -> {:error, :interval_check}
    end
  end

  defp hour_limit_check(%PublishThrottle{hour_count: hour_count}, opt) do
    hour_count_opt = Keyword.get(opt, :hour_limit) || @hour_limit

    case hour_count < hour_count_opt do
      true -> {:ok, :hour_limit_check}
      false -> {:error, :hour_limit_check}
    end
  end

  defp day_limit_check(%PublishThrottle{date_count: day_count}, opt) do
    day_limit_opt = Keyword.get(opt, :day_limit) || @day_total

    case day_count < day_limit_opt do
      true -> {:ok, :day_limit_check}
      false -> {:error, :day_limit_check}
    end
  end
end
