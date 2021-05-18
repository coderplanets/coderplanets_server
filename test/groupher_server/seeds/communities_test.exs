defmodule GroupherServer.Test.Seeds.Communities do
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.User
  alias GroupherServer.CMS
  alias CMS.Delegate.SeedsConfig

  alias Helper.{ORM, Utils}

  # setup do
  # {:ok, user} = db_insert(:user)

  # {:ok, ~m(user category)a}
  # end

  describe "[cms communities seeds]" do
    test "default pl communities seeds works" do
      CMS.seed_communities(:pl)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, results} = ORM.find_all(CMS.Community, %{page: 1, size: 20})
      radom_community = results.entries |> Enum.random()

      {:ok, found} = ORM.find(CMS.Community, radom_community.id, preload: :threads)
      assert length(found.threads) == 6

      {:ok, found} = ORM.find(CMS.Community, radom_community.id, preload: :categories)
      assert length(found.categories) !== 0
    end

    test "city communities seeds works" do
      CMS.seed_communities(:city)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, results} = ORM.find_all(CMS.Community, %{page: 1, size: 20})
      radom_community = results.entries |> Enum.random()

      {:ok, found} = ORM.find(CMS.Community, radom_community.id, preload: :threads)
      assert length(found.threads) == 5

      {:ok, found} = ORM.find(CMS.Community, radom_community.id, preload: :categories)
      assert length(found.categories) !== 0
    end

    test "home community seeds works" do
      CMS.seed_communities(:home)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, community} = ORM.find_by(CMS.Community, %{raw: "home"})
      assert community.title == "coderplanets"
      assert community.raw == "home"

      {:ok, found} = ORM.find(CMS.Community, community.id, preload: :threads)
      assert length(found.threads) == 7
    end

    #
    # test "seeded general community has general tags" do
    #   CMS.seed_communities(:pl)
    #   {:ok, results} = ORM.find_all(CMS.Community, %{page: 1, size: 20})
    #   radom_community = results.entries |> Enum.random()

    #   # test post threads
    #   {:ok, random_community} = ORM.find(CMS.Community, radom_community.id)
    #   {:ok, tags} = CMS.paged_article_tags(%{community_id: random_community.id}, :post)
    #   found_tags = tags |> Utils.pick_by(:title)
    #   config_tags = SeedsConfig.tags(:post) |> Utils.pick_by(:title)
    #   assert found_tags |> Enum.sort() == config_tags |> Enum.sort()

    #   # test job threads
    #   {:ok, random_community} = ORM.find(CMS.Community, radom_community.id)
    #   {:ok, tags} = CMS.paged_article_tags(%{community_id: random_community.id}, :job)
    #   found_tags = tags |> Utils.pick_by(:title)
    #   config_tags = SeedsConfig.tags(:job) |> Utils.pick_by(:title)
    #   assert found_tags |> Enum.sort() == config_tags |> Enum.sort()

    #   # test repo threads
    #   {:ok, random_community} = ORM.find(CMS.Community, radom_community.id)
    #   {:ok, tags} = CMS.paged_article_tags(%{community_id: random_community.id}, :repo)
    #   found_tags = tags |> Utils.pick_by(:title)
    #   config_tags = SeedsConfig.tags(:repo) |> Utils.pick_by(:title)
    #   assert found_tags |> Enum.sort() == config_tags |> Enum.sort()
    # end

    test "seeded home community has home-spec tags" do
      CMS.seed_communities(:home)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, community} = ORM.find_by(CMS.Community, %{raw: "home"})
      assert community.title == "coderplanets"
      assert community.raw == "home"

      {:ok, found} = ORM.find(CMS.Community, community.id, preload: :threads)
      assert length(found.threads) == 7
    end
  end
end
