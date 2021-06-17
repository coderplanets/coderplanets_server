defmodule GroupherServer.Test.Query.Hooks.CiteJob do
  @moduledoc false

  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS

  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    job_attrs = mock_attrs(:job, %{community_id: community.id})

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community job job_attrs user)a}
  end

  describe "[query paged_jobs filter pagination]" do
    # id
    @query """
    query($content: Content!, $id: ID!, $filter: PageFilter!) {
      pagedCitingContents(id: $id, content: $content, filter: $filter) {
        entries {
          id
          title
          user {
            login
            nickname
            avatar
          }
          commentId
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """

    test "should get paged cittings", ~m(guest_conn community job_attrs user)a do
      {:ok, job2} = db_insert(:job)

      {:ok, comment} =
        CMS.create_comment(
          :job,
          job2.id,
          mock_comment(~s(the <a href=#{@site_host}/job/#{job2.id} />)),
          user
        )

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/job/#{job2.id} />),
          ~s(the <a href=#{@site_host}/job/#{job2.id} />)
        )

      job_attrs = job_attrs |> Map.merge(%{body: body})
      {:ok, job_x} = CMS.create_article(community, :job, job_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/job/#{job2.id} />))
      job_attrs = job_attrs |> Map.merge(%{body: body})
      {:ok, job_y} = CMS.create_article(community, :job, job_attrs, user)

      Hooks.Cite.handle(job_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(job_y)

      variables = %{content: "JOB", id: job2.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedCitingContents")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 3
    end
  end
end
