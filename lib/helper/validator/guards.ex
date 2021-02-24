defmodule Helper.Validator.Guards do
  @moduledoc """
  general guards
  """
  defguard g_pos_int(value) when is_integer(value) and value >= 0
  defguard g_not_nil(value) when not is_nil(value)
end
