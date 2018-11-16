defmodule MastaniServer.Test.Seeds.Communities do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS
  alias CMS.Delegate.SeedsConfig

  alias Helper.{Certification, ORM}

  alias Helper.Utils

  # setup do
  # {:ok, user} = db_insert(:user)

  # {:ok, ~m(user category)a}
  # end

  describe "[cms communities seeds]" do
    @tag :wip
    test "default pl communities seeds works" do
      CMS.seed_communities(:pl)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, results} = ORM.find_all(CMS.Community, %{page: 1, size: 20})
      radom_community = results.entries |> Enum.random()

      {:ok, found} = ORM.find(CMS.Community, radom_community.id, preload: :threads)
      assert length(found.threads) == 7

      {:ok, found} = ORM.find(CMS.Community, radom_community.id, preload: :categories)
      assert length(found.categories) !== 0

      # {:ok, tags} = ORM.find_all(CMS.Tag, %{page: 1, size: 20})
      # IO.inspect tags, label: "hello tags"
    end

    @tag :wip
    test "home community seeds works" do
      CMS.seed_communities(:home)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, community} = ORM.find_by(CMS.Community, %{raw: "home"})
      assert community.title == "coderplanets"
      assert community.raw == "home"

      {:ok, found} = ORM.find(CMS.Community, community.id, preload: :threads)
      assert length(found.threads) == 7
    end

    @tag :wip
    test "seeded general community has general tags" do
      CMS.seed_communities(:pl)
      {:ok, results} = ORM.find_all(CMS.Community, %{page: 1, size: 20})
      radom_community = results.entries |> Enum.random()

      # test post threads
      {:ok, random_community} = ORM.find(CMS.Community, radom_community.id)
      {:ok, tags} = CMS.get_tags(random_community, :post)
      found_tags = tags |> Utils.pick_by(:title)
      config_tags = SeedsConfig.tags(:post) |> Utils.pick_by(:title)
      assert found_tags |> Enum.sort() == config_tags |> Enum.sort()

      # test job threads
      {:ok, random_community} = ORM.find(CMS.Community, radom_community.id)
      {:ok, tags} = CMS.get_tags(random_community, :job)
      found_tags = tags |> Utils.pick_by(:title)
      config_tags = SeedsConfig.tags(:job) |> Utils.pick_by(:title)
      assert found_tags |> Enum.sort() == config_tags |> Enum.sort()

      # test video threads
      {:ok, random_community} = ORM.find(CMS.Community, radom_community.id)
      {:ok, tags} = CMS.get_tags(random_community, :video)
      found_tags = tags |> Utils.pick_by(:title)
      config_tags = SeedsConfig.tags(:video) |> Utils.pick_by(:title)
      assert found_tags |> Enum.sort() == config_tags |> Enum.sort()

      # test repo threads
      {:ok, random_community} = ORM.find(CMS.Community, radom_community.id)
      {:ok, tags} = CMS.get_tags(random_community, :repo)
      found_tags = tags |> Utils.pick_by(:title)
      config_tags = SeedsConfig.tags(:repo) |> Utils.pick_by(:title)
      assert found_tags |> Enum.sort() == config_tags |> Enum.sort()
    end

    @tag :wip
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
