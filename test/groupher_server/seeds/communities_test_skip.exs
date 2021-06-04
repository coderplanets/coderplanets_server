defmodule GroupherServer.Test.Seeds.Communities do
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.User
  alias GroupherServer.CMS

  alias CMS.Model.Community
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

    test "home community seeds works" do
      CMS.seed_communities(:home)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, community} = ORM.find_by(Community, %{raw: "home"})
      assert community.title == "coderplanets"
      assert community.raw == "home"

      {:ok, found} = ORM.find(Community, community.id, preload: :threads)
      assert length(found.threads) == 7
    end

    test "seeded home community has home-spec tags" do
      CMS.seed_communities(:home)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, community} = ORM.find_by(Community, %{raw: "home"})
      assert community.title == "coderplanets"
      assert community.raw == "home"

      {:ok, found} = ORM.find(Community, community.id, preload: :threads)
      assert length(found.threads) == 7
    end
  end
end
