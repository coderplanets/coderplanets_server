defmodule Helper.SpecType do
  @moduledoc """
  custom @types
  """

  @typedoc """
  Type GraphQL flavor the error format
  """
  @type gq_error :: {:error, [message: String.t(), code: non_neg_integer()]}

  @typedoc """
  general response conventions
  """
  @type done :: {:ok, map} | {:error, map}

  @type id :: non_neg_integer() | String.t()
end
