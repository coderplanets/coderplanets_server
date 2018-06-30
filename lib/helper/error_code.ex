defmodule Helper.ErrorCode do
  @default_code 4000
  @account_base 4300
  @changeset_base 4100
  @normal_base 4000
  @throttle_base 4200

  # account error code
  def ecode(:account_login), do: @account_base + 1
  def ecode(:passport), do: @account_base + 2
  # ...
  # changeset error code
  def ecode(:changeset), do: @changeset_base + 2
  # ...
  def ecode(:custom), do: @normal_base + 1
  def ecode(:pagination), do: @normal_base + 2

  # throttle
  def ecode(:throttle_inverval), do: @throttle_base + 1
  def ecode(:throttle_hour), do: @throttle_base + 2
  def ecode(:throttle_day), do: @throttle_base + 3

  def ecode(), do: @default_code
  def ecode(_), do: @default_code
end
