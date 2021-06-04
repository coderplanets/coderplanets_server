defmodule GroupherServer.Test.CMS.ArticleCommunity.Job do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Job

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, job} = db_insert(:job)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    job_attrs = mock_attrs(:job, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 job job_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created job has origial community info", ~m(user community job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, job} = ORM.find(Job, job.id, preload: :original_community)

      assert job.original_community_id == community.id
    end

    test "job can be move to other community", ~m(user community community2 job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      assert job.original_community_id == community.id

      {:ok, _} = CMS.move_article(:job, job.id, community2.id)
      {:ok, job} = ORM.find(Job, job.id, preload: [:original_community, :communities])

      assert job.original_community.id == community2.id
      assert not is_nil(Enum.find(job.communities, &(&1.id == community2.id)))
    end

    test "job can be mirror to other community", ~m(user community community2 job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, job} = ORM.find(Job, job.id, preload: :communities)
      assert job.communities |> length == 1

      assert not is_nil(Enum.find(job.communities, &(&1.id == community.id)))

      {:ok, _} = CMS.mirror_article(:job, job.id, community2.id)

      {:ok, job} = ORM.find(Job, job.id, preload: :communities)
      assert job.communities |> length == 2
      assert not is_nil(Enum.find(job.communities, &(&1.id == community.id)))
      assert not is_nil(Enum.find(job.communities, &(&1.id == community2.id)))
    end

    test "job can be unmirror from community",
         ~m(user community community2 community3 job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.mirror_article(:job, job.id, community2.id)
      {:ok, _} = CMS.mirror_article(:job, job.id, community3.id)

      {:ok, job} = ORM.find(Job, job.id, preload: :communities)
      assert job.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:job, job.id, community3.id)
      {:ok, job} = ORM.find(Job, job.id, preload: :communities)
      assert job.communities |> length == 2

      assert is_nil(Enum.find(job.communities, &(&1.id == community3.id)))
    end

    test "job can not unmirror from original community",
         ~m(user community community2 community3 job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.mirror_article(:job, job.id, community2.id)
      {:ok, _} = CMS.mirror_article(:job, job.id, community3.id)

      {:ok, job} = ORM.find(Job, job.id, preload: :communities)
      assert job.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:job, job.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end
  end
end
