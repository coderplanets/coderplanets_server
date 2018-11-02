defmodule MastaniServer.Test.Query.VideosFlags do
  use MastaniServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias MastaniServer.CMS

  alias CMS.Video

  @total_count 35
  @page_size get_config(:general, :page_size)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, community2} = db_insert(:community)
    CMS.create_content(community2, :video, mock_attrs(:video), user)

    videos =
      Enum.reduce(1..@total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_content(community, :video, mock_attrs(:video), user)
        acc ++ [value]
      end)

    video_b = videos |> List.first()
    video_m = videos |> Enum.at(div(@total_count, 2))
    video_e = videos |> List.last()

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user video_b video_m video_e)a}
  end

  describe "[query videos flags]" do
    @query """
    query($filter: PagedArticleFilter!) {
      pagedVideos(filter: $filter) {
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
    @tag :wip
    test "if have pined videos, the pined videos should at the top of entries",
         ~m(guest_conn community video_m)a do
      variables = %{filter: %{community: community.raw}}
      # variables = %{filter: %{}}

      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count

      {:ok, _pined_post} = CMS.pin_content(video_m, community)

      results = guest_conn |> query_result(@query, variables, "pagedVideos")
      entries_first = results["entries"] |> List.first()

      assert results["totalCount"] == @total_count + 1
      assert entries_first["id"] == to_string(video_m.id)
      assert entries_first["pin"] == true
    end

    @tag :wip
    test "pind videos should not appear when page > 1", ~m(guest_conn community)a do
      variables = %{filter: %{page: 2, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")
      assert results |> is_valid_pagination?

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")
      {:ok, _} = CMS.set_community_flags(%Video{id: random_id}, community.id, %{pin: true})
      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
    end

    @tag :wip
    test "if have trashed videos, the trashed videos should not appears in result",
         ~m(guest_conn community)a do
      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")
      {:ok, _} = CMS.set_community_flags(%Video{id: random_id}, community.id, %{trash: true})

      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
      assert results["totalCount"] == @total_count - 1
    end
  end
end
