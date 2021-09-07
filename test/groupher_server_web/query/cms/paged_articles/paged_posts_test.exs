defmodule GroupherServer.Test.Query.PagedArticles.PagedPosts do
  @moduledoc false

  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias GroupherServer.Repo

  alias CMS.Model.Post

  @page_size get_config(:general, :page_size)

  @now Timex.now()
  @last_week Timex.shift(Timex.beginning_of_week(@now), days: -1, seconds: -1)
  @last_month Timex.shift(Timex.beginning_of_month(@now), days: -1, seconds: -1)
  @last_year Timex.shift(Timex.beginning_of_year(@now), days: -3, seconds: -1)

  @today_count 15

  @last_week_count 1
  @last_month_count 1
  @last_year_count 1

  @total_count @today_count + @last_week_count + @last_month_count + @last_year_count

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, post_last_month} = db_insert(:post, %{title: "last month", inserted_at: @last_month})

    {:ok, post_last_week} =
      db_insert(:post, %{title: "last week", inserted_at: @last_week, active_at: @last_week})

    {:ok, post_last_year} =
      db_insert(:post, %{title: "last year", inserted_at: @last_year, active_at: @last_year})

    db_insert_multi(:post, @today_count)

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user post_last_week post_last_month post_last_year)a}
  end

  describe "[query paged_posts filter pagination]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          document {
            bodyHtml
          }
          communities {
            id
            raw
          }
          articleTags {
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
    test "should get pagination info", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == 10
      assert results["totalCount"] == @total_count
      assert results["entries"] |> List.first() |> Map.get("articleTags") |> is_list
    end

    test "should get valid thread document", ~m(guest_conn)a do
      {:ok, user} = db_insert(:user)
      {:ok, community} = db_insert(:community)
      post_attrs = mock_attrs(:post, %{community_id: community.id})
      Process.sleep(2000)
      {:ok, _post} = CMS.create_article(community, :post, post_attrs, user)

      variables = %{filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      post = results["entries"] |> List.first()

      assert not is_nil(get_in(post, ["document", "bodyHtml"]))
    end

    test "support article_tag filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      post_attrs = mock_attrs(:post, %{community_id: community.id})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, _} = CMS.set_article_tag(:post, post.id, article_tag.id)

      variables = %{filter: %{page: 1, size: 10, article_tag: article_tag.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      variables = %{filter: %{page: 1, size: 10, article_tags: [article_tag.raw]}}
      results2 = guest_conn |> query_result(@query, variables, "pagedPosts")
      assert results == results2

      post = results["entries"] |> List.first()
      assert results["totalCount"] == 1
      assert exist_in?(article_tag, post["articleTags"])
    end

    test "support community filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)

      post_attrs = mock_attrs(:post, %{community_id: community.id})
      {:ok, _post} = CMS.create_article(community, :post, post_attrs, user)
      post_attrs2 = mock_attrs(:post, %{community_id: community.id})
      {:ok, _post} = CMS.create_article(community, :post, post_attrs2, user)

      variables = %{filter: %{page: 1, size: 10, community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      post = results["entries"] |> List.first()
      assert results["totalCount"] == 2
      assert exist_in?(%{id: to_string(community.id)}, post["communities"])
    end

    test "request large size fails", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 200}}
      assert guest_conn |> query_get_error?(@query, variables, ecode(:pagination))
    end

    test "request 0 or neg-size fails", ~m(guest_conn)a do
      variables_0 = %{filter: %{page: 1, size: 0}}
      variables_neg_1 = %{filter: %{page: 1, size: -1}}

      assert guest_conn |> query_get_error?(@query, variables_0, ecode(:pagination))
      assert guest_conn |> query_get_error?(@query, variables_neg_1, ecode(:pagination))
    end

    test "pagination should have default page and size arg", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count
    end
  end

  describe "[query paged_posts filter sort]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          inserted_at
          active_at
          author {
            id
            nickname
            avatar
          }
          communities {
            id
            raw
          }
        }
       }
    }
    """

    test "filter community should get posts which belongs to that community",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, post} = CMS.create_article(community, :post, mock_attrs(:post), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert length(results["entries"]) == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post.id)))
    end

    test "should have a active_at same with inserted_at", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, _post} = CMS.create_article(community, :post, mock_attrs(:post), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      post = results["entries"] |> List.first()

      assert post["inserted_at"] == post["active_at"]
    end

    test "filter sort should have default :desc_active", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      active_timestamps = results["entries"] |> Enum.map(& &1["active_at"])

      {:ok, first_inserted_time, 0} = active_timestamps |> List.first() |> DateTime.from_iso8601()
      {:ok, last_inserted_time, 0} = active_timestamps |> List.last() |> DateTime.from_iso8601()

      assert :gt = DateTime.compare(first_inserted_time, last_inserted_time)
    end

    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          views
        }
      }
    }
    """
    test "filter sort MOST_VIEWS should work", ~m(guest_conn)a do
      most_views_post = Post |> order_by(desc: :views) |> limit(1) |> Repo.one()
      variables = %{filter: %{sort: "MOST_VIEWS"}}

      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      find_post = results |> Map.get("entries") |> hd

      # assert find_post["id"] == most_views_post |> Map.get(:id) |> to_string
      assert find_post["views"] == most_views_post |> Map.get(:views)
    end
  end

  describe "[query paged_posts filter has_xxx]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          viewerHasCollected
          viewerHasUpvoted
          viewerHasViewed
          viewerHasReported
          meta {
            latestUpvotedUsers {
              login
            }
          }
        }
        totalCount
      }
    }
    """

    test "has_xxx state should work", ~m(user)a do
      user_conn = simu_conn(:user, user)
      {:ok, community} = db_insert(:community)

      {:ok, post} = CMS.create_article(community, :post, mock_attrs(:post), user)
      {:ok, _post2} = CMS.create_article(community, :post, mock_attrs(:post), user)
      {:ok, _post3} = CMS.create_article(community, :post, mock_attrs(:post), user)

      variables = %{filter: %{community: community.raw}}
      results = user_conn |> query_result(@query, variables, "pagedPosts")
      assert results["totalCount"] == 3

      the_post = Enum.find(results["entries"], &(&1["id"] == to_string(post.id)))
      assert not the_post["viewerHasViewed"]
      assert not the_post["viewerHasUpvoted"]
      assert not the_post["viewerHasCollected"]
      assert not the_post["viewerHasReported"]

      {:ok, _} = CMS.read_article(:post, post.id, user)
      {:ok, _} = CMS.upvote_article(:post, post.id, user)
      {:ok, _} = CMS.collect_article(:post, post.id, user)
      {:ok, _} = CMS.report_article(:post, post.id, "reason", "attr_info", user)

      results = user_conn |> query_result(@query, variables, "pagedPosts")

      the_post = Enum.find(results["entries"], &(&1["id"] == to_string(post.id)))
      assert the_post["viewerHasViewed"]
      assert the_post["viewerHasUpvoted"]
      assert the_post["viewerHasCollected"]
      assert the_post["viewerHasReported"]

      assert user_exist_in?(user, the_post["meta"]["latestUpvotedUsers"])
    end
  end

  # TODO test  sort, tag, community, when ...
  @doc """
  test: FILTER when [TODAY] [THIS_WEEK] [THIS_MONTH] [THIS_YEAR]
  """
  describe "[query paged_posts filter when]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          views
          inserted_at
        }
        totalCount
      }
    }
    """
    test "THIS_YEAR option should work", ~m(guest_conn post_last_year)a do
      variables = %{filter: %{when: "THIS_YEAR"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results["entries"] |> Enum.any?(&(&1["id"] != post_last_year.id))
    end

    test "TODAY option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "TODAY"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      expect_count = @total_count - @last_year_count - @last_month_count - @last_week_count

      assert results |> Map.get("totalCount") == expect_count
    end

    test "THIS_WEEK option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_WEEK"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results |> Map.get("totalCount") == @today_count
    end

    test "THIS_MONTH option should work", ~m(guest_conn post_last_month)a do
      variables = %{filter: %{when: "THIS_MONTH"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results["entries"] |> Enum.any?(&(&1["id"] != post_last_month.id))
    end
  end

  describe "[paged posts active_at]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          insertedAt
          activeAt
        }
      }
    }
    """
    test "latest commented post should appear on top", ~m(guest_conn post_last_week user)a do
      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      entries = results["entries"]
      first_post = entries |> List.first()
      assert first_post["id"] !== to_string(post_last_week.id)

      Process.sleep(1500)
      {:ok, _comment} = CMS.create_comment(:post, post_last_week.id, mock_comment(), user)

      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      entries = results["entries"]
      first_post = entries |> List.first()

      assert first_post["id"] == to_string(post_last_week.id)
    end

    test "comment on very old post have no effect", ~m(guest_conn post_last_year user)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, _comment} = CMS.create_comment(:post, post_last_year.id, mock_comment(), user)

      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      entries = results["entries"]
      first_post = entries |> List.first()

      assert first_post["id"] !== to_string(post_last_year.id)
    end

    test "latest post author commented post have no effect", ~m(guest_conn post_last_week)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, _comment} =
        CMS.create_comment(
          :post,
          post_last_week.id,
          mock_comment(),
          post_last_week.author.user
        )

      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      entries = results["entries"]
      first_post = entries |> List.first()

      assert first_post["id"] !== to_string(post_last_week.id)
    end
  end
end
