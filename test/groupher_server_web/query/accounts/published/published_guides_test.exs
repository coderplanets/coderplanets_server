defmodule GroupherServer.Test.Query.Accounts.Published.Guides do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, guide} = db_insert(:guide)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn community guide user)a}
  end

  describe "[published guides]" do
    @query """
    query($login: String!, $filter: PagedFilter!) {
      pagedPublishedGuides(login: $login, filter: $filter) {
        entries {
          id
          title
          author {
            id
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """

    test "can get published guides", ~m(guest_conn community user)a do
      guide_attrs = mock_attrs(:guide, %{community_id: community.id})

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, guide2} = CMS.create_article(community, :guide, guide_attrs, user)

      variables = %{login: user.login, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedPublishedGuides")

      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(guide.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(guide2.id)))
    end
  end

  describe "[account published comments on guide]" do
    @query """
    query($login: String!, $thread: Thread, $filter: PagedFilter!) {
      pagedPublishedComments(login: $login, thread: $thread, filter: $filter) {
        entries {
          id
          bodyHtml
          author {
            id
          }
          article {
            id
            title
            author {
              nickname
              login
            }
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published comments on guide", ~m(guest_conn user guide)a do
      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:guide, guide.id, mock_comment(), user)
          acc ++ [comment]
        end)

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{login: user.login, thread: "GUIDE", filter: %{page: 1, size: 20}}

      results = guest_conn |> query_result(@query, variables, "pagedPublishedComments")

      entries = results["entries"]
      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert entries |> Enum.all?(&(not is_nil(&1["article"]["author"])))

      assert entries |> Enum.all?(&(&1["article"]["id"] == to_string(guide.id)))
      assert entries |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert entries |> Enum.any?(&(&1["id"] == random_comment_id))
    end
  end
end
