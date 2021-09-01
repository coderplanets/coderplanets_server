defmodule GroupherServer.Test.Query.PagedArticles.PagedBlogs do
  @moduledoc false
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]
  import Ecto.Query, warn: false

  alias GroupherServer.CMS
  alias GroupherServer.Repo

  alias CMS.Model.Blog

  @page_size get_config(:general, :page_size)

  @now Timex.now()
  @last_week Timex.shift(Timex.beginning_of_week(@now), days: -1, seconds: -1)
  @last_month Timex.shift(Timex.beginning_of_month(@now), days: -7, seconds: -1)
  @last_year Timex.shift(Timex.beginning_of_year(@now), days: -2, seconds: -1)

  @today_count 15

  @last_week_count 1
  @last_month_count 1
  @last_year_count 1

  @total_count @today_count + @last_week_count + @last_month_count + @last_year_count

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, blog_last_week} =
      db_insert(:blog, %{title: "last week", inserted_at: @last_week, active_at: @last_week})

    db_insert(:blog, %{title: "last month", inserted_at: @last_month})

    {:ok, blog_last_year} =
      db_insert(:blog, %{title: "last year", inserted_at: @last_year, active_at: @last_year})

    db_insert_multi(:blog, @today_count)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user blog_last_week blog_last_year)a}
  end

  describe "[query paged_blogs filter pagination]" do
    @query """
    query($filter: PagedBlogsFilter!) {
      pagedBlogs(filter: $filter) {
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
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == 10
      assert results["totalCount"] == @total_count
      assert results["entries"] |> List.first() |> Map.get("articleTags") |> is_list
    end

    test "should get valid thread document", ~m(guest_conn)a do
      {:ok, user} = db_insert(:user)
      {:ok, community} = db_insert(:community)
      blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      Process.sleep(2000)
      {:ok, _blog} = CMS.create_article(community, :blog, blog_attrs, user)

      variables = %{filter: %{page: 1, size: 30}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      blog = results["entries"] |> List.first()
      assert not is_nil(get_in(blog, ["document", "bodyHtml"]))
    end

    test "support article_tag filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, _} = CMS.set_article_tag(:blog, blog.id, article_tag.id)

      variables = %{filter: %{page: 1, size: 10, article_tag: article_tag.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      variables = %{filter: %{page: 1, size: 10, article_tags: [article_tag.raw]}}
      results2 = guest_conn |> query_result(@query, variables, "pagedBlogs")
      assert results == results2

      blog = results["entries"] |> List.first()
      assert results["totalCount"] == 1
      assert exist_in?(article_tag, blog["articleTags"])
    end

    test "support multi-tag (article_tags) filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, article_tag3} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)

      {:ok, _} = CMS.set_article_tag(:blog, blog.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:blog, blog.id, article_tag2.id)

      variables = %{
        filter: %{page: 1, size: 10, article_tags: [article_tag.raw, article_tag2.raw]}
      }

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      blog = results["entries"] |> List.first()
      assert results["totalCount"] == 1
      assert exist_in?(article_tag, blog["articleTags"])
      assert exist_in?(article_tag2, blog["articleTags"])
      assert not exist_in?(article_tag3, blog["articleTags"])
    end

    test "should not have pined blogs when filter have article_tag or article_tags",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      {:ok, pinned_blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, _} = CMS.pin_article(:blog, pinned_blog.id, community.id)

      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, _} = CMS.set_article_tag(:blog, blog.id, article_tag.id)

      variables = %{
        filter: %{page: 1, size: 10, community: community.raw, article_tag: article_tag.raw}
      }

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert not exist_in?(pinned_blog, results["entries"])
      assert exist_in?(blog, results["entries"])

      variables = %{
        filter: %{page: 1, size: 10, community: community.raw, article_tags: [article_tag.raw]}
      }

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert not exist_in?(pinned_blog, results["entries"])
      assert exist_in?(blog, results["entries"])
    end

    test "support community filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)

      blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      {:ok, _blog} = CMS.create_article(community, :blog, blog_attrs, user)
      blog_attrs2 = mock_attrs(:blog, %{community_id: community.id})
      {:ok, _blog} = CMS.create_article(community, :blog, blog_attrs2, user)

      variables = %{filter: %{page: 1, size: 10, community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      blog = results["entries"] |> List.first()
      assert results["totalCount"] == 2
      assert exist_in?(%{id: to_string(community.id)}, blog["communities"])
    end

    test "request large size fails", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 200}}
      assert guest_conn |> query_get_error?(@query, variables, ecode(:pagination))
    end

    test "request 0 or neg-size fails", ~m(guest_conn)a do
      variables_0 = %{filter: %{page: 1, size: 0}}
      variables_neg_1 = %{filter: %{page: 1, size: -1}}

      assert guest_conn |> query_get_error?(@query, variables_0)
      assert guest_conn |> query_get_error?(@query, variables_neg_1)
    end

    test "pagination should have default page and size arg", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count
    end
  end

  describe "[query paged_blogs filter has_xxx]" do
    @query """
    query($filter: PagedBlogsFilter!) {
      pagedBlogs(filter: $filter) {
        entries {
          id
          viewerHasCollected
          viewerHasUpvoted
          viewerHasViewed
          viewerHasReported
        }
        totalCount
      }
    }
    """

    test "has_xxx state should work", ~m(user)a do
      user_conn = simu_conn(:user, user)
      {:ok, community} = db_insert(:community)

      {:ok, blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)
      {:ok, _blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)
      {:ok, _blog3} = CMS.create_article(community, :blog, mock_attrs(:blog), user)

      variables = %{filter: %{community: community.raw}}
      results = user_conn |> query_result(@query, variables, "pagedBlogs")
      assert results["totalCount"] == 3

      the_blog = Enum.find(results["entries"], &(&1["id"] == to_string(blog.id)))
      assert not the_blog["viewerHasViewed"]
      assert not the_blog["viewerHasUpvoted"]
      assert not the_blog["viewerHasCollected"]
      assert not the_blog["viewerHasReported"]

      {:ok, _} = CMS.read_article(:blog, blog.id, user)
      {:ok, _} = CMS.upvote_article(:blog, blog.id, user)
      {:ok, _} = CMS.collect_article(:blog, blog.id, user)
      {:ok, _} = CMS.report_article(:blog, blog.id, "reason", "attr_info", user)

      results = user_conn |> query_result(@query, variables, "pagedBlogs")
      the_blog = Enum.find(results["entries"], &(&1["id"] == to_string(blog.id)))
      assert the_blog["viewerHasViewed"]
      assert the_blog["viewerHasUpvoted"]
      assert the_blog["viewerHasCollected"]
      assert the_blog["viewerHasReported"]
    end
  end

  describe "[query paged_blogs filter sort]" do
    @query """
    query($filter: PagedBlogsFilter!) {
      pagedBlogs(filter: $filter) {
        entries {
          id
          inserted_at
          active_at
          author {
            id
            nickname
            avatar
          }
        }
       }
    }
    """

    test "filter community should get blogs which belongs to that community",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert length(results["entries"]) == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(blog.id)))
    end

    test "should have a active_at same with inserted_at", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, _blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      blog = results["entries"] |> List.first()

      assert blog["inserted_at"] == blog["active_at"]
    end

    test "filter sort should have default :desc_active", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      active_timestamps = results["entries"] |> Enum.map(& &1["active_at"])

      {:ok, first_active_time, 0} = active_timestamps |> List.first() |> DateTime.from_iso8601()
      {:ok, last_active_time, 0} = active_timestamps |> List.last() |> DateTime.from_iso8601()

      assert :gt = DateTime.compare(first_active_time, last_active_time)
    end

    @query """
    query($filter: PagedBlogsFilter!) {
      pagedBlogs(filter: $filter) {
        entries {
          id
          views
        }
      }
    }
    """

    test "filter sort MOST_VIEWS should work", ~m(guest_conn)a do
      most_views_blog = Blog |> order_by(desc: :views) |> limit(1) |> Repo.one()
      variables = %{filter: %{sort: "MOST_VIEWS"}}

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      find_blog = results |> Map.get("entries") |> hd

      assert find_blog["views"] == most_views_blog |> Map.get(:views)
    end
  end

  # TODO test  sort, tag, community, when ...
  @doc """
  test: FILTER when [TODAY] [THIS_WEEK] [THIS_MONTH] [THIS_YEAR]
  """
  describe "[query paged_blogs filter when]" do
    @query """
    query($filter: PagedBlogsFilter!) {
      pagedBlogs(filter: $filter) {
        entries {
          id
          views
          inserted_at
        }
        totalCount
      }
    }
    """
    test "THIS_YEAR option should work", ~m(guest_conn blog_last_year)a do
      variables = %{filter: %{when: "THIS_YEAR"}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert results["entries"] |> Enum.any?(&(&1["id"] != blog_last_year.id))
    end

    test "TODAY option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "TODAY"}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      expect_count = @total_count - @last_year_count - @last_month_count - @last_week_count

      assert results |> Map.get("totalCount") == expect_count
    end

    test "THIS_WEEK option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_WEEK"}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert results |> Map.get("totalCount") == @today_count
    end

    test "THIS_MONTH option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_MONTH"}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      {_, cur_week_month, _} = @now |> Date.to_erl()
      {_, last_week_month, _} = @last_week |> Date.to_erl()

      expect_count =
        case cur_week_month == last_week_month do
          true ->
            @total_count - @last_year_count - @last_month_count

          false ->
            @total_count - @last_year_count - @last_month_count - @last_week_count
        end

      assert results |> Map.get("totalCount") == expect_count
    end
  end

  describe "[query paged_blogs filter extra]" do
    @query """
    query($filter: PagedBlogsFilter!) {
      pagedBlogs(filter: $filter) {
        entries {
          id
          title
        }
        totalCount
      }
    }
    """
    test "basic filter should work", ~m(guest_conn)a do
      {:ok, blog} = db_insert(:blog)
      {:ok, blog2} = db_insert(:blog)

      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(blog.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(blog2.id)))
    end
  end

  describe "[paged blogs active_at]" do
    @query """
    query($filter: PagedBlogsFilter!) {
      pagedBlogs(filter: $filter) {
        entries {
          id
          insertedAt
          activeAt
        }
      }
    }
    """

    test "latest commented blog should appear on top", ~m(guest_conn blog_last_week user)a do
      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      entries = results["entries"]
      first_blog = entries |> List.first()
      assert first_blog["id"] !== to_string(blog_last_week.id)

      Process.sleep(1500)
      {:ok, _comment} = CMS.create_comment(:blog, blog_last_week.id, mock_comment(), user)

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      entries = results["entries"]
      first_blog = entries |> List.first()

      assert first_blog["id"] == to_string(blog_last_week.id)
    end

    test "comment on very old blog have no effect", ~m(guest_conn blog_last_year user)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, _comment} = CMS.create_comment(:blog, blog_last_year.id, mock_comment(), user)

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      entries = results["entries"]
      first_blog = entries |> List.first()

      assert first_blog["id"] !== to_string(blog_last_year.id)
    end

    test "latest blog author commented blog have no effect", ~m(guest_conn blog_last_week)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, _comment} =
        CMS.create_comment(
          :blog,
          blog_last_week.id,
          mock_comment(),
          blog_last_week.author.user
        )

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      entries = results["entries"]
      first_blog = entries |> List.first()

      assert first_blog["id"] !== to_string(blog_last_week.id)
    end
  end
end
