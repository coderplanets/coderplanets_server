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
      # IO.inspect results.entries |> Enum.random(), label: "threads results"
      radom_community = results.entries |> Enum.random()
      # IO.inspect radom_community, label: "hello radom_community"

      {:ok, found} = ORM.find(CMS.Community, radom_community.id, preload: :threads)
      assert length(found.threads) !== 0

      {:ok, found} = ORM.find(CMS.Community, radom_community.id, preload: :categories)
      assert length(found.categories) !== 0
    end
  end
end
