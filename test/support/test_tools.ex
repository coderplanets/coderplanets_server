defmodule MastaniServer.TestTools do
  @moduledoc """
  helper for reduce import mudules in test files
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use MastaniServerWeb.ConnCase, async: true

      import MastaniServer.Support.Factory
      import MastaniServer.Test.ConnSimulator
      import MastaniServer.Test.AssertHelper
      import Ecto.Query, warn: false
      import Helper.ErrorCode
      import Helper.Utils, only: [camelize_map_key: 1]

      import ShortMaps
    end
  end
end
