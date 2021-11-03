defmodule GroupherServer.Test.CMS.Search do
  use GroupherServer.TestTools

  # alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, _community} = db_insert(:community, %{title: "react"})
    {:ok, _community} = db_insert(:community, %{title: "php"})
    {:ok, _community} = db_insert(:community, %{title: "每日妹子"})
    {:ok, _community} = db_insert(:community, %{title: "javascript"})
    {:ok, _community} = db_insert(:community, %{title: "java"})

    {:ok, _community} = db_insert(:post, %{title: "react"})
    {:ok, _community} = db_insert(:post, %{title: "php"})
    {:ok, _community} = db_insert(:post, %{title: "每日妹子"})
    {:ok, _community} = db_insert(:post, %{title: "javascript"})
    {:ok, _community} = db_insert(:post, %{title: "java"})

    {:ok, ~m(user)a}
  end

  describe "[cms search post]" do
    test "search post by full title should valid paged posts" do
      {:ok, searched} = CMS.search_articles(:post, %{title: "react"})

      assert searched |> is_valid_pagination?(:raw)
      assert searched.total_count == 1
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "react"
    end

    test "search post blur title should return valid communities" do
      {:ok, searched} = CMS.search_articles(:post, %{title: "reac"})
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "react"

      {:ok, searched} = CMS.search_articles(:post, %{title: "rea"})
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "react"

      {:ok, searched} = CMS.search_articles(:post, %{title: "eac"})
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "react"

      {:ok, searched} = CMS.search_articles(:post, %{title: "每日"})
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "每日妹子"

      {:ok, searched} = CMS.search_articles(:post, %{title: "javasc"})
      assert searched.total_count == 1
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "javascript"

      {:ok, searched} = CMS.search_articles(:post, %{title: "java"})
      assert searched.total_count == 2
      assert searched.entries |> Enum.any?(&(&1.title == "java"))
      assert searched.entries |> Enum.any?(&(&1.title == "javascript"))
    end

    test "search non exsit community should get empty pagi data" do
      {:ok, searched} = CMS.search_communities("non-exsit")
      assert searched |> is_valid_pagination?(:raw, :empty)
    end
  end

  describe "[cms search community with category]" do
    test "community with category can be searched" do
      {:ok, community} = db_insert(:community, %{title: "cool-pl"})
      {:ok, category} = db_insert(:category, %{raw: "pl"})

      {:ok, _} = CMS.set_category(community, category)

      {:ok, searched} = CMS.search_communities("cool-pl", "pl")
      assert searched.entries |> List.first() |> Map.get(:title) == "cool-pl"
    end
  end

  describe "[cms search community]" do
    test "search community by full title should valid paged communities" do
      {:ok, searched} = CMS.search_communities("react")

      assert searched |> is_valid_pagination?(:raw)
      assert searched.total_count == 1
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "react"
    end

    test "search community blur title should return valid communities" do
      {:ok, searched} = CMS.search_communities("reac")
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "react"

      {:ok, searched} = CMS.search_communities("rea")
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "react"

      {:ok, searched} = CMS.search_communities("eac")
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "react"

      {:ok, searched} = CMS.search_communities("每日")
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "每日妹子"

      {:ok, searched} = CMS.search_communities("javasc")
      assert searched.total_count == 1
      assert searched.entries |> Enum.at(0) |> Map.get(:title) == "javascript"

      {:ok, searched} = CMS.search_communities("java")
      assert searched.total_count == 2
      assert searched.entries |> Enum.any?(&(&1.title == "java"))
      assert searched.entries |> Enum.any?(&(&1.title == "javascript"))
    end

    test "search non exsit community should get empty pagi data" do
      {:ok, searched} = CMS.search_communities("non-exsit")
      assert searched |> is_valid_pagination?(:raw, :empty)
    end
  end
end
