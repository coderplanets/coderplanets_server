defmodule GroupherServer.Test.Articles.Job do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias Helper.Converter.{EditorToHTML, HtmlSanitizer}

  alias EditorToHTML.{Class, Validator}
  alias CMS.Model.{Author, Job, Community}

  alias Helper.ORM

  @root_class Class.article()
  @last_year Timex.shift(Timex.beginning_of_year(Timex.now()), days: -3, seconds: -1)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 community job_attrs)a}
  end

  describe "[cms jobs curd]" do
    test "can create job with valid attrs", ~m(user community job_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      body_map = Jason.decode!(job.body)

      assert job.title == job_attrs.title
      assert body_map |> Validator.is_valid()
      assert job.body_html |> String.contains?(~s(<div class="#{@root_class["viewer"]}">))
      assert job.body_html |> String.contains?(~s(<p id="block-))

      paragraph_text = body_map["blocks"] |> List.first() |> get_in(["data", "text"])
      assert job.digest == paragraph_text |> HtmlSanitizer.strip_all_tags()
    end

    test "created job should have a acitve_at field, same with inserted_at",
         ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      assert job.active_at == job.inserted_at
    end

    test "read job should update views and meta viewed_user_list",
         ~m(job_attrs community user user2)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.read_article(:job, job.id, user)
      {:ok, _created} = ORM.find(Job, job.id)

      # same user duplicate case
      {:ok, _} = CMS.read_article(:job, job.id, user)
      {:ok, created} = ORM.find(Job, job.id)

      assert created.meta.viewed_user_ids |> length == 1
      assert user.id in created.meta.viewed_user_ids

      {:ok, _} = CMS.read_article(:job, job.id, user2)
      {:ok, created} = ORM.find(Job, job.id)

      assert created.meta.viewed_user_ids |> length == 2
      assert user.id in created.meta.viewed_user_ids
      assert user2.id in created.meta.viewed_user_ids
    end

    test "read job should contains viewer_has_xxx state", ~m(job_attrs community user user2)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, job} = CMS.read_article(:job, job.id, user)

      assert not job.viewer_has_collected
      assert not job.viewer_has_upvoted
      assert not job.viewer_has_reported

      {:ok, job} = CMS.read_article(:job, job.id)

      assert not job.viewer_has_collected
      assert not job.viewer_has_upvoted
      assert not job.viewer_has_reported

      {:ok, job} = CMS.read_article(:job, job.id, user2)

      assert not job.viewer_has_collected
      assert not job.viewer_has_upvoted
      assert not job.viewer_has_reported

      {:ok, _} = CMS.upvote_article(:job, job.id, user)
      {:ok, _} = CMS.collect_article(:job, job.id, user)
      {:ok, _} = CMS.report_article(:job, job.id, "reason", "attr_info", user)

      {:ok, job} = CMS.read_article(:job, job.id, user)

      assert job.viewer_has_collected
      assert job.viewer_has_upvoted
      assert job.viewer_has_reported
    end

    test "create job with an exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:job, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_article(ivalid_community, :job, invalid_attrs, user)
    end
  end

  describe "[cms job sink/undo_sink]" do
    test "if a job is too old, read job should update can_undo_sink flag",
         ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      assert job.meta.can_undo_sink

      {:ok, job_last_year} = db_insert(:job, %{title: "last year", inserted_at: @last_year})
      {:ok, job_last_year} = CMS.read_article(:job, job_last_year.id)
      assert not job_last_year.meta.can_undo_sink

      {:ok, job_last_year} = CMS.read_article(:job, job_last_year.id, user)
      assert not job_last_year.meta.can_undo_sink
    end

    test "can sink a job", ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      assert not job.meta.is_sinked

      {:ok, job} = CMS.sink_article(:job, job.id)
      assert job.meta.is_sinked
      assert job.active_at == job.inserted_at
    end

    test "can undo sink job", ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, job} = CMS.sink_article(:job, job.id)
      assert job.meta.is_sinked
      assert job.meta.last_active_at == job.active_at

      {:ok, job} = CMS.undo_sink_article(:job, job.id)
      assert not job.meta.is_sinked
      assert job.active_at == job.meta.last_active_at
    end

    test "can not undo sink to old job", ~m()a do
      {:ok, job_last_year} = db_insert(:job, %{title: "last year", inserted_at: @last_year})

      {:error, reason} = CMS.undo_sink_article(:job, job_last_year.id)
      is_error?(reason, :undo_sink_old_article)
    end
  end
end
