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
    @tag :wip
    test "user can have default customization without payment", ~m(user)a do
      {:ok, result} = Accounts.set_customization(user, :banner_layout, "digest")
      assert result.banner_layout == "digest"
    end

    @tag :wip
    test "user set non exsit customization fails", ~m(user)a do
      {:error, _} = Accounts.set_customization(user, :non_exsit, true)
    end

    @tag :wip2
    test "user set advance customization without payment fails", ~m(user)a do
      {:error, _} = Accounts.set_customization(user, :theme, "blue")
    end

    @tag :wip2
    test "user can set multiable customization at once", ~m(user)a do
      {:ok, result} =
        Accounts.set_customization(user, %{
          content_divider: true,
          sidebar_layout: %{hello: :world},
          sidebar_communities_index: %{javascript: 1, elixir: 2}
        })

      assert result.content_divider == true
      assert result.sidebar_layout == %{hello: :world}
      assert result.sidebar_communities_index == %{javascript: 1, elixir: 2}

      assert {:error, _result} =
               Accounts.set_customization(user, %{content_divider: true, no_exsit: true})

      assert {:error, _result} = Accounts.set_customization(user, %{})
    end
  end
end
