defmodule GroupherServer.Test.Query.PagedArticles.PagedRepos do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias GroupherServer.Repo

  @page_size get_config(:general, :page_size)

  @cur_date Timex.now()
  @last_week Timex.shift(Timex.beginning_of_week(@cur_date), days: -1, microseconds: -1)
  @last_month Timex.shift(Timex.beginning_of_month(@cur_date), days: -7, microseconds: -1)
  @last_year Timex.shift(Timex.beginning_of_year(@cur_date), days: -2, microseconds: -1)

  @today_count 15

  @last_week_count 1
  @last_month_count 1
  @last_year_count 1

  @total_count @today_count + @last_week_count + @last_month_count + @last_year_count

  setup do
    {:ok, user} = db_insert(:user)

    db_insert_multi(:repo, @today_count)
    db_insert(:repo, %{repo_name: "last week", inserted_at: @last_week})
    db_insert(:repo, %{repo_name: "last month", inserted_at: @last_month})
    {:ok, repo_last_year} = db_insert(:repo, %{repo_name: "last year", inserted_at: @last_year})

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user repo_last_year)a}
  end

  describe "[query paged_repos filter pagination]" do
    @query """
    query($filter: PagedReposFilter!) {
      pagedRepos(filter: $filter) {
        entries {
          id
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
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == 10
      assert results["totalCount"] == @total_count
      assert results["entries"] |> List.first() |> Map.get("articleTags") |> is_list
    end

    test "support article_tag filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      repo_attrs = mock_attrs(:repo, %{community_id: community.id})
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :repo, article_tag_attrs, user)
      {:ok, _} = CMS.set_article_tag(:repo, repo.id, article_tag.id)

      variables = %{filter: %{page: 1, size: 10, article_tag: article_tag.title}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      repo = results["entries"] |> List.first()
      assert results["totalCount"] == 1
      assert exist_in?(article_tag, repo["articleTags"], :string_key)
    end

    test "support community filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)

      repo_attrs = mock_attrs(:repo, %{community_id: community.id})
      {:ok, _repo} = CMS.create_article(community, :repo, repo_attrs, user)
      repo_attrs2 = mock_attrs(:repo, %{community_id: community.id})
      {:ok, _repo} = CMS.create_article(community, :repo, repo_attrs2, user)

      variables = %{filter: %{page: 1, size: 10, community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      repo = results["entries"] |> List.first()
      assert results["totalCount"] == 2
      assert exist_in?(%{id: to_string(community.id)}, repo["communities"], :string_key)
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
      results = guest_conn |> query_result(@query, variables, "pagedRepos")
      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count
    end
  end

  describe "[query paged_repos filter has_xxx]" do
    @query """
    query($filter: PagedReposFilter!) {
      pagedRepos(filter: $filter) {
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

      {:ok, repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)
      {:ok, _repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)
      {:ok, _repo3} = CMS.create_article(community, :repo, mock_attrs(:repo), user)

      variables = %{filter: %{community: community.raw}}
      results = user_conn |> query_result(@query, variables, "pagedRepos")
      assert results["totalCount"] == 3

      the_repo = Enum.find(results["entries"], &(&1["id"] == to_string(repo.id)))
      assert not the_repo["viewerHasViewed"]
      assert not the_repo["viewerHasUpvoted"]
      assert not the_repo["viewerHasCollected"]
      assert not the_repo["viewerHasReported"]

      {:ok, _} = CMS.read_article(:repo, repo.id, user)
      {:ok, _} = CMS.upvote_article(:repo, repo.id, user)
      {:ok, _} = CMS.collect_article(:repo, repo.id, user)
      {:ok, _} = CMS.report_article(:repo, repo.id, "reason", "attr_info", user)

      results = user_conn |> query_result(@query, variables, "pagedRepos")
      the_repo = Enum.find(results["entries"], &(&1["id"] == to_string(repo.id)))
      assert the_repo["viewerHasViewed"]
      assert the_repo["viewerHasUpvoted"]
      assert the_repo["viewerHasCollected"]
      assert the_repo["viewerHasReported"]
    end
  end

  describe "[query paged_repos filter sort]" do
    @query """
    query($filter: PagedReposFilter!) {
      pagedRepos(filter: $filter) {
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
    test "filter community should get repos which belongs to that community",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      assert length(results["entries"]) == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(repo.id)))
    end

    test "should have a active_at same with inserted_at", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, _repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")
      repo = results["entries"] |> List.first()

      assert repo["inserted_at"] == repo["active_at"]
    end

    test "filter sort should have default :desc_active", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")
      active_timestamps = results["entries"] |> Enum.map(& &1["active_at"])

      {:ok, first_active_time, 0} = active_timestamps |> List.first() |> DateTime.from_iso8601()
      {:ok, last_active_time, 0} = active_timestamps |> List.last() |> DateTime.from_iso8601()

      assert :gt = DateTime.compare(first_active_time, last_active_time)
    end

    @query """
    query($filter: PagedReposFilter!) {
      pagedRepos(filter: $filter) {
        entries {
          id
          views
        }
      }
    }
    """
    test "filter sort MOST_VIEWS should work", ~m(guest_conn)a do
      most_views_repo = CMS.Repo |> order_by(desc: :views) |> limit(1) |> Repo.one()
      variables = %{filter: %{sort: "MOST_VIEWS"}}

      results = guest_conn |> query_result(@query, variables, "pagedRepos")
      find_repo = results |> Map.get("entries") |> hd

      assert find_repo["views"] == most_views_repo |> Map.get(:views)
    end
  end

  describe "[query paged_repos filter when]" do
    @query """
    query($filter: PagedReposFilter!) {
      pagedRepos(filter: $filter) {
        entries {
          id
          views
          inserted_at
        }
        totalCount
      }
    }
    """
    test "THIS_YEAR option should work", ~m(guest_conn repo_last_year)a do
      variables = %{filter: %{when: "THIS_YEAR"}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      assert results["entries"] |> Enum.any?(&(&1["id"] != repo_last_year.id))
    end

    test "TODAY option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "TODAY"}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      expect_count = @total_count - @last_year_count - @last_month_count - @last_week_count

      assert results |> Map.get("totalCount") == expect_count
    end

    test "THIS_WEEK option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_WEEK"}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      assert results |> Map.get("totalCount") == @today_count
    end

    test "THIS_MONTH option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_MONTH"}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      {_, cur_week_month, _} = @cur_date |> Date.to_erl()
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

  describe "[query paged_repos filter extra]" do
    @query """
    query($filter: PagedReposFilter!) {
      pagedRepos(filter: $filter) {
        entries {
          id
          starCount
          forkCount
        }
        totalCount
      }
    }
    """
    test "most star option should work", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 20, sort: "MOST_GITHUB_STAR"}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      first_count = results["entries"] |> Enum.at(0) |> Map.get("starCount")
      last_count = results["entries"] |> Enum.at(10) |> Map.get("starCount")

      assert first_count > last_count
    end

    test "most fork option should work", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 20, sort: "MOST_GITHUB_FORK"}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      first_count = results["entries"] |> Enum.at(0) |> Map.get("forkCount")
      last_count = results["entries"] |> Enum.at(10) |> Map.get("forkCount")

      assert first_count > last_count
    end
  end
end
