defmodule Helper.CommonTypes do
  @moduledoc """
  common types for lint
  """

  @type github_contributor :: %{
          github_id: String.t(),
          avatar: String.t(),
          html_url: String.t(),
          nickname: String.t(),
          bio: nil | String.t(),
          location: nil | String.t(),
          company: nil | String.t()
        }

  @type custom_error :: {:error, [message: String.t(), code: Number.t()]}
end
