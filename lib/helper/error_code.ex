defmodule Helper.ErrorCode do
  @default_code 4000
  @account_base 4300
  @changeset_base 4100
  @normal_base 4000

  # account error code
  def ecode(:account_login), do: @account_base + 1
  def ecode(:passport), do: @account_base + 2
  # ...
  # changeset error code
  def ecode(:changeset), do: @changeset_base + 2
  # ...
  def ecode(:custom), do: @normal_base + 1
  def ecode(:pagination), do: @normal_base + 2

  def ecode(), do: @default_code
  def ecode(_), do: @default_code
end
