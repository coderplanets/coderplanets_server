defmodule GroupherServer.Test.CMS.Hooks.CiteJob do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Job, Comment, CitedArtiment}
  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, job} = db_insert(:job)
    {:ok, job2} = db_insert(:job)
    {:ok, job3} = db_insert(:job)
    {:ok, job4} = db_insert(:job)
    {:ok, job5} = db_insert(:job)

    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 community job job2 job3 job4 job5 job_attrs)a}
  end

  describe "[cite basic]" do
    test "cited multi job should work", ~m(user community job2 job3 job4 job5 job_attrs)a do
      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/job/#{job2.id} /> and <a href=#{@site_host}/job/#{job2.id}>same la</a> is awesome, the <a href=#{
            @site_host
          }/job/#{job3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/job/#{job2.id} class=#{job2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/job/#{job4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/job/#{job5.id}> again</a>)
        )

      job_attrs = job_attrs |> Map.merge(%{body: body})
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/job/#{job3.id} />))
      job_attrs = job_attrs |> Map.merge(%{body: body})
      {:ok, job_n} = CMS.create_article(community, :job, job_attrs, user)

      Hooks.Cite.handle(job)
      Hooks.Cite.handle(job_n)

      {:ok, job2} = ORM.find(Job, job2.id)
      {:ok, job3} = ORM.find(Job, job3.id)
      {:ok, job4} = ORM.find(Job, job4.id)
      {:ok, job5} = ORM.find(Job, job5.id)

      assert job2.meta.citing_count == 1
      assert job3.meta.citing_count == 2
      assert job4.meta.citing_count == 1
      assert job5.meta.citing_count == 1
    end

    test "cited job itself should not work", ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/job/#{job.id} />))
      {:ok, job} = CMS.update_article(job, %{body: body})

      Hooks.Cite.handle(job)

      {:ok, job} = ORM.find(Job, job.id)
      assert job.meta.citing_count == 0
    end

    test "cited comment itself should not work", ~m(user job)a do
      {:ok, cited_comment} = CMS.create_comment(:job, job.id, mock_rich_text("hello"), user)

      {:ok, comment} =
        CMS.update_comment(
          cited_comment,
          mock_comment(
            ~s(the <a href=#{@site_host}/job/#{job.id}?comment_id=#{cited_comment.id} />)
          )
        )

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 0
    end

    test "can cite job's comment in job", ~m(community user job job2 job_attrs)a do
      {:ok, comment} = CMS.create_comment(:job, job.id, mock_rich_text("hello"), user)

      body =
        mock_rich_text(~s(the <a href=#{@site_host}/job/#{job2.id}?comment_id=#{comment.id} />))

      job_attrs = job_attrs |> Map.merge(%{body: body})

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      Hooks.Cite.handle(job)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: comment.id})

      # 被 job 以 comment link 的方式引用了
      assert cited_content.job_id == job.id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cite a comment in a comment", ~m(user job)a do
      {:ok, cited_comment} = CMS.create_comment(:job, job.id, mock_rich_text("hello"), user)

      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/job/#{job.id}?comment_id=#{cited_comment.id} />)
        )

      {:ok, comment} = CMS.create_comment(:job, job.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: cited_comment.id})
      assert comment.id == cited_content.comment_id
      assert cited_comment.id == cited_content.cited_by_id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cited job inside a comment", ~m(user job job2 job3 job4 job5)a do
      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/job/#{job2.id} /> and <a href=#{@site_host}/job/#{job2.id}>same la</a> is awesome, the <a href=#{
            @site_host
          }/job/#{job3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/job/#{job2.id} class=#{job2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/job/#{job4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/job/#{job5.id}> again</a>)
        )

      {:ok, comment} = CMS.create_comment(:job, job.id, comment_body, user)
      Hooks.Cite.handle(comment)

      comment_body = mock_rich_text(~s(the <a href=#{@site_host}/job/#{job3.id} />))
      {:ok, comment} = CMS.create_comment(:job, job.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, job2} = ORM.find(Job, job2.id)
      {:ok, job3} = ORM.find(Job, job3.id)
      {:ok, job4} = ORM.find(Job, job4.id)
      {:ok, job5} = ORM.find(Job, job5.id)

      assert job2.meta.citing_count == 1
      assert job3.meta.citing_count == 2
      assert job4.meta.citing_count == 1
      assert job5.meta.citing_count == 1
    end
  end

  describe "[cite pagi]" do
    test "can get paged cited articles.", ~m(user community job2 job_attrs)a do
      {:ok, comment} =
        CMS.create_comment(
          :job,
          job2.id,
          mock_comment(~s(the <a href=#{@site_host}/job/#{job2.id} />)),
          user
        )

      Process.sleep(1000)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/job/#{job2.id} />),
          ~s(the <a href=#{@site_host}/job/#{job2.id} />)
        )

      job_attrs = job_attrs |> Map.merge(%{body: body})
      {:ok, job_x} = CMS.create_article(community, :job, job_attrs, user)

      Process.sleep(1000)
      body = mock_rich_text(~s(the <a href=#{@site_host}/job/#{job2.id} />))
      job_attrs = job_attrs |> Map.merge(%{body: body})
      {:ok, job_y} = CMS.create_article(community, :job, job_attrs, user)

      Hooks.Cite.handle(job_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(job_y)

      {:ok, result} = CMS.paged_citing_contents("JOB", job2.id, %{page: 1, size: 10})

      entries = result.entries

      result_comment = entries |> List.first()
      result_job_x = entries |> Enum.at(1)
      result_job_y = entries |> List.last()

      article_map_keys = [:block_linker, :id, :inserted_at, :thread, :title, :user]

      assert result_comment.comment_id == comment.id
      assert result_comment.id == job2.id
      assert result_comment.title == job2.title

      assert result_job_x.id == job_x.id
      assert result_job_x.block_linker |> length == 2
      assert result_job_x |> Map.keys() == article_map_keys

      assert result_job_y.id == job_y.id
      assert result_job_y.block_linker |> length == 1
      assert result_job_y |> Map.keys() == article_map_keys

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 3
    end
  end
end
