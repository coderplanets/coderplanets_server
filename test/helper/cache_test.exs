defmodule GroupherServer.Test.Helper.Cache do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true
  alias Helper.Cache

  describe "[cache test]" do
    @tag :wip
    test "cache get unexsit key should get nil" do
      assert {:ok, nil} = Cache.get("no exsit")
      assert {:ok, nil} = Cache.get(:no_exsit)
    end

    @tag :wip
    test "cache put should work" do
      assert {:ok, nil} = Cache.get(:data)

      assert {:ok, true} = Cache.put(:data, "value")
      assert {:ok, "value"} = Cache.get(:data)

      # can override
      assert {:ok, true} = Cache.put(:data, :value)
      assert {:ok, :value} = Cache.get(:data)

      # complex data
      assert {:ok, true} = Cache.put("namespace.aaa.bbb", [1, %{a: "2"}])
      assert {:ok, [1, %{a: "2"}]} = Cache.get("namespace.aaa.bbb")
    end
  end
end
