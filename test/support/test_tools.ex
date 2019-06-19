defmodule GroupherServer.TestTools do
  @moduledoc """
  helper for reduce import mudules in test files
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use GroupherServerWeb.ConnCase, async: true

      import GroupherServer.Support.Factory
      import GroupherServer.Test.ConnSimulator
      import GroupherServer.Test.AssertHelper
      import Ecto.Query, warn: false
      import Helper.ErrorCode
      import Helper.Utils, only: [camelize_map_key: 1, camelize_map_key: 2]

      import ShortMaps
    end
  end
end
