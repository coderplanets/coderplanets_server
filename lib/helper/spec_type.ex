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

  @typedoc """
  general contribute type for wiki and cheatshet
  """
  @type github_contributor2 :: %{
          github_id: String.t(),
          avatar: String.t(),
          html_url: String.t(),
          nickname: String.t(),
          bio: nil | String.t(),
          location: nil | String.t(),
          company: nil | String.t()
        }
end
