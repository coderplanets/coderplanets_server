defmodule Helper.Validator.Guards do
  @moduledoc """
  general guards
  """
  defguard g_pos_int(value) when is_integer(value) and value >= 0
  defguard g_not_nil(value) when not is_nil(value)

  defguard g_none_empty_str(value) when is_binary(value) and byte_size(value) > 0

  defguard g_is_id(value) when is_binary(value) or is_integer(value)
end
