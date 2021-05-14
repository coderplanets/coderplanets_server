defmodule GroupherServer.Test.Job do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 community job_attrs)a}
  end

  describe "[cms jobs curd]" do
    alias CMS.Community

    test "can create a job with valid attrs", ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, found} = ORM.find(CMS.Job, job.id)
      assert found.id == job.id
      assert found.title == job.title
    end

    test "read job should update views and meta viewed_user_list",
         ~m(job_attrs community user user2)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.read_article(:job, job.id, user)
      {:ok, _created} = ORM.find(CMS.Job, job.id)

      # same user duplicate case
      {:ok, _} = CMS.read_article(:job, job.id, user)
      {:ok, created} = ORM.find(CMS.Job, job.id)

      assert created.meta.viewed_user_ids |> length == 1
      assert user.id in created.meta.viewed_user_ids

      {:ok, _} = CMS.read_article(:job, job.id, user2)
      {:ok, created} = ORM.find(CMS.Job, job.id)

      assert created.meta.viewed_user_ids |> length == 2
      assert user.id in created.meta.viewed_user_ids
      assert user2.id in created.meta.viewed_user_ids
    end

    test "can create job with exsited tags", ~m(user community job_attrs)a do
      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      job_with_tags = Map.merge(job_attrs, %{tags: [%{id: tag1.id}, %{id: tag2.id}]})

      {:ok, created} = CMS.create_article(community, :job, job_with_tags, user)
      {:ok, found} = ORM.find(CMS.Job, created.id, preload: :tags)

      assert found.tags |> Enum.any?(&(&1.id == tag1.id))
      assert found.tags |> Enum.any?(&(&1.id == tag2.id))
    end

    test "create job with invalid tags fails", ~m(user community job_attrs)a do
      {:ok, tag1} = db_insert(:tag)
      {:ok, tag2} = db_insert(:tag)

      job_with_tags =
        Map.merge(job_attrs, %{tags: [%{id: tag1.id}, %{id: tag2.id}, %{id: non_exsit_id()}]})

      {:error, _} = CMS.create_article(community, :job, job_with_tags, user)
      {:error, _} = ORM.find_by(CMS.Job, %{title: job_attrs.title})
    end

    test "create job with an exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:job, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_article(ivalid_community, :job, invalid_attrs, user)
    end
  end
end
