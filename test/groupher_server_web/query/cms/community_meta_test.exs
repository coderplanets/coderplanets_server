defmodule GroupherServer.Test.Query.CMS.CommunityMeta do
  @moduledoc false
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.User
  alias GroupherServer.CMS

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, user} = db_insert(:user)

    community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})

    {:ok, ~m(guest_conn community_attrs user)a}
  end

  describe "[community meta]" do
    @query """
    query($id: ID) {
      community(id: $id) {
        id
        title
        meta {
          articlesCount
          postsCount
          jobsCount
          reposCount
        }
      }
    }
    """
    @tag :wip3
    test "community have valid [thread]s_count in meta", ~m(guest_conn community_attrs user)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _post} = CMS.create_article(community, :post, mock_attrs(:post), user)
      {:ok, _post} = CMS.create_article(community, :post, mock_attrs(:post), user)
      {:ok, _post} = CMS.create_article(community, :job, mock_attrs(:job), user)
      {:ok, _post} = CMS.create_article(community, :repo, mock_attrs(:repo), user)

      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")

      meta = results["meta"]
      assert meta["articlesCount"] == 4
      assert meta["postsCount"] == 2
      assert meta["jobsCount"] == 1
      assert meta["reposCount"] == 1
    end
  end
end
