defmodule GroupherServer.Test.Seeds.CommunitySeed do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Community
  alias Helper.ORM

  describe "[special communities seeds]" do
    test "can seed home community" do
      {:ok, community} = CMS.seed_community(:home)
      {:ok, found} = ORM.find(Community, community.id, preload: [threads: :thread])

      assert community.title == "CoderPlanets"
      assert community.raw == "home"
      assert found.threads |> length == 5

      threads = found.threads |> Enum.map(& &1.thread.title)
      assert threads == ["帖子", "雷达", "博客", "工作", "CPer"]
      # IO.inspect(found, label: "found --> ")
    end

    # test "blackhole community" do
    #   {:ok, community} = CMS.seed_community(:blackhole)
    #   {:ok, found} = ORM.find(Community, community.id, preload: [threads: :thread])

    #   assert community.title == "黑洞"
    #   assert community.raw == "blackhole"
    #   assert found.threads |> length == 2

    #   threads = found.threads |> Enum.map(& &1.thread.title)
    #   assert threads == ["帖子", "账户"]
    # end

    test "Feedback community" do
      {:ok, community} = CMS.seed_community(:feedback)
      {:ok, found} = ORM.find(Community, community.id, preload: [threads: :thread])

      assert community.title == "反馈与建议"
      assert community.raw == "feedback"
      assert found.threads |> length == 3

      threads = found.threads |> Enum.map(& &1.thread.title)
      assert "帖子" in threads
      assert "看板" in threads
      assert "分布" in threads
    end

    # Makers,  广告墙,  求助，外包合作
    test "Makers community" do
    end

    test "Adwall community" do
    end

    test "Ask community" do
    end

    test "outwork community" do
    end
  end

  describe "[common communities seeds]" do
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

    test "can seed a general lang community" do
      {:ok, community} = CMS.seed_community("elixir", :pl)
      {:ok, found} = ORM.find(Community, community.id, preload: [threads: :thread])

      filter = %{community_id: community.id, thread: "POST"}
      {:ok, tags} = CMS.paged_article_tags(filter)
      tags_titles = tags |> Enum.map(& &1.title)

      assert tags_titles == ["求助", "分享推荐", "讨论", "学习资源", "小聚", "杂谈", "社区事务"]

      assert community.title == "elixir"
      assert community.raw == "elixir"

      # threads = found.threads |> Enum.map(& &1.thread.title)
      # assert threads == ["帖子", "雷达", "博客", "101", "awesome", "作品", "工作", "分布", "设置"]
    end

    test "can seed multi lang communities" do
      {:ok, _} = CMS.seed_communities(:pl)

      {:ok, communities} = ORM.find_all(Community, %{page: 1, size: 20})

      # assert communities.total_count == 9
      radom_community = communities.entries |> Enum.random()
      {:ok, found} = ORM.find(Community, radom_community.id, preload: [threads: :thread])
      assert length(found.threads) == 6

      # filter = %{community_id: radom_community.id, thread: "POST"}
      # {:ok, tags} = CMS.paged_article_tags(filter)
      # tags_titles = tags |> Enum.map(& &1.title)
      # assert tags_titles == ["求助", "讨论", "推荐", "小聚", "其他"]

      # threads = found.threads |> Enum.map(& &1.thread.title)
      # assert threads == ["帖子", "雷达", "博客", "101", "awesome", "作品", "工作", "分布", "设置"]
    end

    test "can seed a general framework community" do
      {:ok, community} = CMS.seed_community("react", :framework)
      {:ok, found} = ORM.find(Community, community.id, preload: [threads: :thread])

      filter = %{community_id: community.id, thread: "POST"}
      {:ok, tags} = CMS.paged_article_tags(filter)
      tags_titles = tags |> Enum.map(& &1.title)

      assert tags_titles == ["求助", "分享推荐", "讨论", "学习资源", "小聚", "杂谈", "社区事务"]

      assert community.title == "react"
      assert community.raw == "react"

      threads = found.threads |> Enum.map(& &1.thread.title)
      assert threads == ["帖子", "雷达", "博客", "作品", "工作", "分布"]
    end
  end
end
