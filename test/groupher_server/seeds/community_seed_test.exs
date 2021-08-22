defmodule GroupherServer.Test.Seeds.CommunitySeed do
  @moduledoc false

  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.Model.User
  alias GroupherServer.CMS

  alias CMS.Model.{Community, ArticleTag}
  # alias CMS.Delegate.SeedsConfig

  alias Helper.ORM

  # setup do
  # {:ok, user} = db_insert(:user)

  # {:ok, ~m(user category)a}
  # end

  describe "[cms communities seeds]" do
    @tag :wip2
    test "seed home community should works" do
      {:ok, community} = CMS.seed_community(:home)
      {:ok, found} = ORM.find(Community, community.id, preload: [threads: :thread])

      assert community.title == "coderplanets"
      assert community.raw == "home"
      assert found.threads |> length == 6

      threads = found.threads |> Enum.map(& &1.thread.title)
      assert threads == ["帖子", "雷达", "博客", "工作", "CPer", "设置"]
      # IO.inspect(found, label: "found --> ")
    end

    @tag :wip2
    test "can seed a city community" do
      {:ok, community} = CMS.seed_community("chengdu", :city)
      {:ok, found} = ORM.find(Community, community.id, preload: [threads: :thread])

      filter = %{community_id: community.id, thread: "POST"}
      {:ok, tags} = CMS.paged_article_tags(filter)
      tags_titles = tags |> Enum.map(& &1.title)

      assert tags_titles == ["打听", "讨论", "下班后", "推荐", "二手", "小聚", "吐槽", "求/转/合租", "奇奇怪怪"]

      assert community.title == "成都"
      assert community.raw == "chengdu"

      threads = found.threads |> Enum.map(& &1.thread.title)
      assert threads == ["帖子", "团队", "工作"]
    end

    @tag :wip
    test "can seed multi city communities" do
      {:ok, _} = CMS.seed_communities(:city)

      {:ok, communities} = ORM.find_all(Community, %{page: 1, size: 20})

      assert communities.total_count == 9
      radom_community = communities.entries |> Enum.random()
      {:ok, found} = ORM.find(Community, radom_community.id, preload: [threads: :thread])
      assert length(found.threads) == 3

      filter = %{community_id: radom_community.id, thread: "POST"}
      {:ok, tags} = CMS.paged_article_tags(filter)
      tags_titles = tags |> Enum.map(& &1.title)
      assert tags_titles == ["打听", "讨论", "下班后", "推荐", "二手", "小聚", "吐槽", "求/转/合租", "奇奇怪怪"]

      threads = found.threads |> Enum.map(& &1.thread.title)
      assert threads == ["帖子", "团队", "工作"]
    end

    @tag :wip2
    test "can seed a general lang community" do
      {:ok, community} = CMS.seed_community("elixir", :pl)
      {:ok, found} = ORM.find(Community, community.id, preload: [threads: :thread])

      assert community.title == "elixir"
      assert community.raw == "elixir"

      threads = found.threads |> Enum.map(& &1.thread.title)
      assert threads == ["帖子", "雷达", "博客", "101", "awesome", "作品", "工作", "分布", "设置"]
    end

    # @tag :wip2
    test "can seed multi cities community" do
      {:ok, _} = CMS.seed_communities(:city)
      {:ok, communities} = ORM.find_all(Community, %{page: 1, size: 20})
      radom_community = communities.entries |> Enum.random()
      {:ok, found} = ORM.find(Community, radom_community.id, preload: [threads: :thread])
      assert length(found.threads) == 3

      threads = found.threads |> Enum.map(& &1.thread.title)
      assert threads == ["帖子", "团队", "工作"]
    end

    # @tag :wip2
    test "seed pl & framework community should works" do
      #
    end

    # @tag :wip2
    test "seed city community should works" do
      #
    end

    test "default pl communities seeds works" do
      CMS.seed_communities(:pl)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, results} = ORM.find_all(Community, %{page: 1, size: 20})
      radom_community = results.entries |> Enum.random()

      {:ok, found} = ORM.find(Community, radom_community.id, preload: :threads)
      assert length(found.threads) == 6

      {:ok, found} = ORM.find(Community, radom_community.id, preload: :categories)
      assert length(found.categories) !== 0
    end

    test "city communities seeds works" do
      CMS.seed_communities(:city)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, results} = ORM.find_all(Community, %{page: 1, size: 20})
      radom_community = results.entries |> Enum.random()

      {:ok, found} = ORM.find(Community, radom_community.id, preload: :threads)
      assert length(found.threads) == 5

      {:ok, found} = ORM.find(Community, radom_community.id, preload: :categories)
      assert length(found.categories) !== 0
    end
  end
end
