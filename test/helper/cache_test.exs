defmodule GroupherServer.Test.Helper.Cache do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true
  alias Helper.Cache

  describe "[cache test]" do
    test "cache get unexsit key should get nil" do
      assert {:error, nil} = Cache.get("no exsit")
      assert {:error, nil} = Cache.get(:no_exsit)
    end

    test "cache put should work" do
      assert {:error, nil} = Cache.get(:data)

      assert {:ok, true} = Cache.put(:data, "value")
      assert {:ok, "value"} = Cache.get(:data)

      # can override
      assert {:ok, true} = Cache.put(:data, :value)
      assert {:ok, :value} = Cache.get(:data)

      # complex data
      assert {:ok, true} = Cache.put("namespace.aaa.bbb", [1, %{a: "2"}])
      assert {:ok, [1, %{a: "2"}]} = Cache.get("namespace.aaa.bbb")
    end

    test "cache can be clear" do
      assert {:ok, true} = Cache.put(:data, "value")
      assert {:ok, "value"} = Cache.get(:data)

      assert {:ok, _} = Cache.clear_all()
      assert {:error, nil} = Cache.get(:data)
    end

    test "cache expire should work" do
      assert {:ok, true} = Cache.put(:data, "value", expire: 1000)
      assert {:ok, "value"} = Cache.get(:data)
      Process.sleep(900)
      assert {:ok, "value"} = Cache.get(:data)
      Process.sleep(1200)
      assert {:error, nil} = Cache.get(:data)
    end
  end
end
