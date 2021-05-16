defmodule GroupherServer.Test.Helper.Cache do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true
  alias Helper.Cache

  @pool :common

  describe "[cache test]" do
    test "cache get unexsit key should get nil" do
      assert {:error, nil} = Cache.get(@pool, "no exsit")
      assert {:error, nil} = Cache.get(@pool, :no_exsit)
    end

    test "cache put should work" do
      assert {:error, nil} = Cache.get(@pool, :data)

      assert {:ok, true} = Cache.put(@pool, :data, "value")
      assert {:ok, "value"} = Cache.get(@pool, :data)

      # can override
      assert {:ok, true} = Cache.put(@pool, :data, :value)
      assert {:ok, :value} = Cache.get(@pool, :data)

      # complex data
      assert {:ok, true} = Cache.put(@pool, "namespace.aaa.bbb", [1, %{a: "2"}])
      assert {:ok, [1, %{a: "2"}]} = Cache.get(@pool, "namespace.aaa.bbb")
    end

    test "cache can be clear" do
      assert {:ok, true} = Cache.put(@pool, :data, "value")
      assert {:ok, "value"} = Cache.get(@pool, :data)

      assert {:ok, _} = Cache.clear(@pool)
      assert {:error, nil} = Cache.get(@pool, :data)
    end

    test "cache expire should work" do
      assert {:ok, true} = Cache.put(@pool, :data, "value", expire_sec: 1)
      assert {:ok, "value"} = Cache.get(@pool, :data)
      Process.sleep(800)
      assert {:ok, "value"} = Cache.get(@pool, :data)
      Process.sleep(500)
      assert {:error, nil} = Cache.get(@pool, :data)
    end
  end
end
