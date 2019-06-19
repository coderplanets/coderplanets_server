defmodule GroupherServer.Test.Accounts.Customization do
  use GroupherServer.TestTools

  alias GroupherServer.Accounts
  # import Helper.Utils
  # alias GroupherServer.{Accounts}

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, ~m(user)a}
  end

  describe "[user customization]" do
    test "user can have default customization", ~m(user)a do
      {:ok, result} = Accounts.get_customization(user)

      default = %{
        banner_layout: "digest",
        brainwash_free: false,
        community_chart: false,
        content_divider: false,
        content_hover: true,
        contents_layout: "digest",
        display_density: "20",
        mark_viewed: true,
        sidebar_communities_index: %{},
        theme: "cyan"
      }

      assert result == default
    end

    test "user can set default customization without payment", ~m(user)a do
      {:ok, result} = Accounts.set_customization(user, :banner_layout, "digest")
      assert result.banner_layout == "digest"
    end

    test "user can set contentHover without payment", ~m(user)a do
      {:ok, result} = Accounts.set_customization(user, :content_hover, false)
      assert result.content_hover == false
    end

    test "user set non exsit customization fails", ~m(user)a do
      {:error, _} = Accounts.set_customization(user, :non_exsit, true)
    end

    # test "user set advance customization without payment fails", ~m(user)a do
    # {:error, _} = Accounts.set_customization(user, :theme, "blue")
    # end

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
