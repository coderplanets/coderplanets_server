defmodule MastaniServer.Test.Query.PagedJobs do
  use MastaniServer.TestTools

  import Helper.Utils, only: [get_config: 2]
  import Ecto.Query, warn: false

  alias MastaniServer.CMS
  alias MastaniServer.Repo

  alias CMS.Job

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

    db_insert_multi(:job, @today_count)
    db_insert(:job, %{title: "last week", inserted_at: @last_week})
    db_insert(:job, %{title: "last month", inserted_at: @last_month})
    {:ok, job_last_year} = db_insert(:job, %{title: "last year", inserted_at: @last_year})

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user job_last_year)a}
  end

  describe "[query paged_jobs filter pagination]" do
    @query """
    query($filter: PagedJobsFilter!) {
      pagedJobs(filter: $filter) {
        entries {
          id
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
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == 10
      assert results["totalCount"] == @total_count
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
      results = guest_conn |> query_result(@query, variables, "pagedJobs")
      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count
    end
  end

  describe "[query paged_jobss filter sort]" do
    @query """
    query($filter: PagedJobsFilter!) {
      pagedJobs(filter: $filter) {
        entries {
          id
          inserted_at
          author {
            id
            nickname
            avatar
          }
        }
       }
    }
    """
    test "filter community should get jobs which belongs to that community",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, job} = CMS.create_content(community, :job, mock_attrs(:job), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert length(results["entries"]) == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
    end

    @tag :skip_travis
    test "filter sort should have default :desc_inserted", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")
      inserted_timestamps = results["entries"] |> Enum.map(& &1["inserted_at"])

      {:ok, first_inserted_time, 0} =
        inserted_timestamps |> List.first() |> DateTime.from_iso8601()

      {:ok, last_inserted_time, 0} = inserted_timestamps |> List.last() |> DateTime.from_iso8601()

      assert :gt = DateTime.compare(first_inserted_time, last_inserted_time)
    end

    @query """
    query($filter: PagedJobsFilter!) {
      pagedJobs(filter: $filter) {
        entries {
          id
          views
        }
      }
    }
    """
    test "filter sort MOST_VIEWS should work", ~m(guest_conn)a do
      most_views_job = Job |> order_by(desc: :views) |> limit(1) |> Repo.one()
      variables = %{filter: %{sort: "MOST_VIEWS"}}

      results = guest_conn |> query_result(@query, variables, "pagedJobs")
      find_job = results |> Map.get("entries") |> hd

      assert find_job["views"] == most_views_job |> Map.get(:views)
    end
  end

  # TODO test  sort, tag, community, when ...
  @doc """
  test: FILTER when [TODAY] [THIS_WEEK] [THIS_MONTH] [THIS_YEAR]
  """
  describe "[query paged_jobs filter when]" do
    @query """
    query($filter: PagedJobsFilter!) {
      pagedJobs(filter: $filter) {
        entries {
          id
          body
          company
          views
          inserted_at
        }
        totalCount
      }
    }
    """
    test "THIS_YEAR option should work", ~m(guest_conn job_last_year)a do
      variables = %{filter: %{when: "THIS_YEAR"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["entries"] |> Enum.any?(&(&1["id"] != job_last_year.id))
    end

    test "TODAY option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "TODAY"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      expect_count = @total_count - @last_year_count - @last_month_count - @last_week_count

      assert results |> Map.get("totalCount") == expect_count
    end

    test "THIS_WEEK option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_WEEK"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results |> Map.get("totalCount") == @today_count
    end

    test "THIS_MONTH option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_MONTH"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

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

  describe "[query paged_jobs filter extra]" do
    @query """
    query($filter: PagedJobsFilter!) {
      pagedJobs(filter: $filter) {
        entries {
          id
          salary
          exp
          field
          finance
          scale
          education
        }
        totalCount
      }
    }
    """
    test "salary option should work", ~m(guest_conn)a do
      {:ok, job} = db_insert(:job, %{salary: "2k-5k"})
      {:ok, job2} = db_insert(:job, %{salary: "5k-10k"})

      variables = %{filter: %{page: 1, size: 20, salary: "2k-5k"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.all?(&(&1["salary"] == "2k-5k"))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job2.id)))
    end

    test "field option should work", ~m(guest_conn)a do
      {:ok, job} = db_insert(:job, %{field: "互联网"})
      {:ok, job2} = db_insert(:job, %{field: "电子商务"})

      variables = %{filter: %{page: 1, size: 20, field: "互联网"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.all?(&(&1["field"] == "互联网"))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job2.id)))
    end

    test "finance option should work", ~m(guest_conn)a do
      {:ok, job} = db_insert(:job, %{finance: "未融资"})
      {:ok, job2} = db_insert(:job, %{finance: "天使轮"})

      variables = %{filter: %{page: 1, size: 20, finance: "未融资"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.all?(&(&1["finance"] == "未融资"))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job2.id)))
    end

    test "scale option should work", ~m(guest_conn)a do
      {:ok, job} = db_insert(:job, %{scale: "少于15人"})
      {:ok, job2} = db_insert(:job, %{scale: "15-50人"})

      variables = %{filter: %{page: 1, size: 20, scale: "少于15人"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.all?(&(&1["scale"] == "少于15人"))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job2.id)))
    end

    test "exp option should work", ~m(guest_conn)a do
      {:ok, job} = db_insert(:job, %{exp: "应届"})
      {:ok, job2} = db_insert(:job, %{exp: "3年以下"})

      variables = %{filter: %{page: 1, size: 20, exp: "应届"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.all?(&(&1["exp"] == "应届"))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job2.id)))

      variables = %{filter: %{page: 1, size: 20, exp: "不限"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["totalCount"] > @total_count
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job2.id)))
    end

    test "education option should work", ~m(guest_conn)a do
      {:ok, job} = db_insert(:job, %{education: "不限"})
      {:ok, job2} = db_insert(:job, %{education: "大专"})
      {:ok, job3} = db_insert(:job, %{education: "本科"})
      {:ok, job4} = db_insert(:job, %{education: "硕士"})
      {:ok, job5} = db_insert(:job, %{education: "博士"})

      variables = %{filter: %{page: 1, size: 30, education: "不限"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job2.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job3.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job4.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job5.id)))

      variables = %{filter: %{page: 1, size: 30, education: "大专"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job2.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job3.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job4.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job5.id)))

      variables = %{filter: %{page: 1, size: 30, education: "本科"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job2.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job3.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job4.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job5.id)))

      variables = %{filter: %{page: 1, size: 30, education: "硕士"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job2.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job3.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job4.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job5.id)))

      variables = %{filter: %{page: 1, size: 30, education: "博士"}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job2.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job3.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(job4.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job5.id)))
    end

    test "multi filter should work together", ~m(guest_conn)a do
      {:ok, job} =
        db_insert(:job, %{
          title: "hehe",
          scale: "少于15人",
          exp: "本科",
          field: "教育",
          finance: "D轮以上",
          salary: "20k-50k"
        })

      variables = %{
        filter: %{
          page: 1,
          size: 20,
          scale: "少于15人",
          exp: "本科",
          field: "教育",
          finance: "D轮以上",
          salary: "20k-50k"
        }
      }

      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job.id)))
    end
  end
end
