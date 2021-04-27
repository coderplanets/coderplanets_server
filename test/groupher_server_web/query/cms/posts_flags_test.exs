defmodule GroupherServer.Test.Query.PostsFlags do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  # alias GroupherServer.Repo

  alias CMS.Post

  @total_count 35
  @page_size get_config(:general, :page_size)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, community2} = db_insert(:community)
    CMS.create_content(community2, :post, mock_attrs(:post), user)

    posts =
      Enum.reduce(1..@total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_content(community, :post, mock_attrs(:post), user)
        acc ++ [value]
      end)

    post_b = posts |> List.first()
    post_m = posts |> Enum.at(div(@total_count, 2))
    post_e = posts |> List.last()

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user post_b post_m post_e)a}
  end

  describe "[query posts flags]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          pin
          communities {
            raw
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "if have pined posts, the pined posts should at the top of entries",
         ~m(guest_conn community post_m)a do
      variables = %{filter: %{community: community.raw}}
      # variables = %{filter: %{}}

      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count

      {:ok, _pined_post} = CMS.pin_content(post_m, community)

      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      entries_first = results["entries"] |> List.first()

      assert results["totalCount"] == @total_count
      assert entries_first["id"] == to_string(post_m.id)
      assert entries_first["pin"] == true
    end

    test "pind posts should not appear when page > 1", ~m(guest_conn community)a do
      variables = %{filter: %{page: 2, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      assert results |> is_valid_pagination?

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")

      {:ok, _pined_post} = CMS.pin_content(%Post{id: random_id}, community)

      # {:ok, _} = CMS.set_community_flags(community, %Post{id: random_id}, %{pin: true})
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
    end

    test "if have trashed posts, the trashed posts should not appears in result",
         ~m(guest_conn community)a do
      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")
      {:ok, _} = CMS.set_community_flags(community, %Post{id: random_id}, %{trash: true})

      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
      assert results["totalCount"] == @total_count - 1
    end
  end
end
