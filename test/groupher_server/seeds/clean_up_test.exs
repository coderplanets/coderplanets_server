defmodule GroupherServer.Test.Seeds.CleanUp do
  @moduledoc false
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.Model.User
  alias GroupherServer.CMS

  alias CMS.Model.{Thread, CommunityThread, ArticleTag, Post}
  # alias CMS.Delegate.SeedsConfig

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user community post_attrs)a}
  end

  describe "[community clean up]" do
    test "can clean up a community", ~m(user post_attrs)a do
      {:ok, community} = CMS.seed_community(:home)
      {:ok, _post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, found} = ORM.find_all(ArticleTag, %{page: 1, size: 20})
      assert found.total_count !== 0

      CMS.clean_up_community(:home)

      {:ok, found} = ORM.find_all(Post, %{page: 1, size: 20})
      assert found.total_count == 0

      {:ok, found} = ORM.find_all(CommunityThread, %{page: 1, size: 20})
      assert found.total_count == 0

      {:ok, found} = ORM.find_all(Thread, %{page: 1, size: 20})
      assert found.total_count !== 0

      {:ok, found} = ORM.find_all(ArticleTag, %{page: 1, size: 20})
      assert found.total_count == 0
    end
  end
end
