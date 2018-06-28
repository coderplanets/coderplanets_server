defmodule MastaniServer.TestTools do
  use ExUnit.CaseTemplate

  using do
    quote do
      use MastaniServerWeb.ConnCase, async: true

      import MastaniServer.Factory
      import MastaniServer.Test.ConnSimulator
      import MastaniServer.Test.AssertHelper
      import Ecto.Query, warn: false
      import Helper.ErrorCode

      import ShortMaps
    end
  end
end
