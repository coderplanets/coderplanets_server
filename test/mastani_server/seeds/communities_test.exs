defmodule MastaniServer.Test.Seeds.Communities do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS

  alias Helper.{Certification, ORM}

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
    end

    @tag :wip
    test "home community seeds works" do
      CMS.seed_communities(:home)

      # {:ok, results} = ORM.find_all(CMS.Thread, %{page: 1, size: 20})
      {:ok, community} = ORM.find_by(CMS.Community, %{raw: "home"})
      assert community.title == "coderplanets"
      assert community.raw == "home"

      {:ok, found} = ORM.find(CMS.Community, community.id, preload: :threads)
      assert length(found.threads) == 6
    end
  end
end
