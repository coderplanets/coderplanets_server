defmodule Helper.ErrorCode do
  @moduledoc """
  error code map for all site
  """
  @default_base 4000
  @changeset_base 4100
  @throttle_base 4200
  @account_base 4300

  # account error code
  def ecode(:account_login), do: @account_base + 1
  def ecode(:passport), do: @account_base + 2
  # ...
  # changeset error code
  def ecode(:changeset), do: @changeset_base + 2
  # default errors
  def ecode(:custom), do: @default_base + 1
  def ecode(:pagination), do: @default_base + 2
  def ecode(:not_exsit), do: @default_base + 3
  def ecode(:already_did), do: @default_base + 4
  def ecode(:self_conflict), do: @default_base + 5
  def ecode(:react_fails), do: @default_base + 6
  def ecode(:already_exsit), do: @default_base + 7
  def ecode(:update_fails), do: @default_base + 8
  def ecode(:delete_fails), do: @default_base + 9
  def ecode(:create_fails), do: @default_base + 10
  def ecode(:exsit_pending_bill), do: @default_base + 11
  def ecode(:bill_state), do: @default_base + 12
  def ecode(:bill_action), do: @default_base + 13
  def ecode(:editor_data_parse), do: @default_base + 14
  # throttle
  def ecode(:throttle_inverval), do: @throttle_base + 1
  def ecode(:throttle_hour), do: @throttle_base + 2
  def ecode(:throttle_day), do: @throttle_base + 3
  def ecode, do: @default_base
  # def ecode(_), do: @default_base
end
