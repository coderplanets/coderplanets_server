defmodule MastaniServer.Test.Accounts.Customization do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts
  # import Helper.Utils
  # alias MastaniServer.{Accounts}

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, ~m(user)a}
  end

  describe "[user customization]" do
    test "user can have default customization without payment", ~m(user)a do
      {:ok, result} = Accounts.add_custom_setting(user, :theme, true)
      assert result.theme == true

      {:ok, result} = Accounts.add_custom_setting(user, :theme)
      assert result.theme == true

      {:error, _result} = Accounts.add_custom_setting(user, :non_exsit, true)
    end

    test "user set advance customization without payment fails", ~m(user)a do
      {:error, _result} = Accounts.add_custom_setting(user, :non_exsit, true)
      {:error, _result} = Accounts.add_custom_setting(user, :brainwash_free, true)
    end

    test "user can set advance customization after pay for it", ~m(user)a do
      {:error, _result} = Accounts.add_custom_setting(user, :brainwash_free, true)
      {:ok, _result} = Accounts.purchase_service(user, :brainwash_free)

      {:ok, _result} = Accounts.add_custom_setting(user, :brainwash_free, true)
    end

    test "user can set multiable customization at once", ~m(user)a do
      {:ok, result} =
        Accounts.add_custom_setting(user, %{theme: true, sidebar_layout: %{hello: :world}})

      assert result.theme == true
      assert result.sidebar_layout == %{hello: :world}

      assert {:error, _result} = Accounts.add_custom_setting(user, %{theme: true, no_exsit: true})
      assert {:error, _result} = Accounts.add_custom_setting(user, %{})
    end

    test "user can purchase multiable items at once", ~m(user)a do
      {:ok, result} =
        Accounts.purchase_service(user, %{brainwash_free: true, community_chart: true})

      assert result.brainwash_free == true
      assert result.community_chart == true

      assert {:error, _result} =
               Accounts.purchase_service(user, %{brainwash_free: true, no_exsit: true})

      assert {:error, _result} = Accounts.purchase_service(user, %{})
    end
  end
end
