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
      assert exist_in?(community2, job.communities)
    end

    test "tags should be clean after job move to other community",
         ~m(user community community2 job_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :job, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :job, article_tag_attrs2, user)

      {:ok, _job} = CMS.set_article_tag(:job, job.id, article_tag.id)
      {:ok, job} = CMS.set_article_tag(:job, job.id, article_tag2.id)

      assert job.article_tags |> length == 2
      assert job.original_community_id == community.id

      {:ok, _} = CMS.move_article(:job, job.id, community2.id)

      {:ok, job} =
        ORM.find(Job, job.id, preload: [:original_community, :communities, :article_tags])

      assert job.article_tags |> length == 0
      assert job.original_community.id == community2.id
      assert exist_in?(community2, job.communities)
    end

    test "job move to other community with new tag",
         ~m(user community community2 job_attrs)a do
      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, article_tag0} = CMS.create_article_tag(community, :job, article_tag_attrs0, user)
      {:ok, article_tag} = CMS.create_article_tag(community2, :job, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :job, article_tag_attrs2, user)

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.set_article_tag(:job, job.id, article_tag0.id)
      {:ok, _} = CMS.set_article_tag(:job, job.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:job, job.id, article_tag2.id)

      {:ok, job} = ORM.find(Job, job.id, preload: [:article_tags])
      assert job.article_tags |> length == 3

      {:ok, _} = CMS.move_article(:job, job.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, job} =
        ORM.find(Job, job.id, preload: [:original_community, :communities, :article_tags])

      assert job.original_community.id == community2.id
      assert job.article_tags |> length == 2

      assert not exist_in?(article_tag0, job.article_tags)
      assert exist_in?(article_tag, job.article_tags)
      assert exist_in?(article_tag2, job.article_tags)
    end

    test "job can be mirror to other community", ~m(user community community2 job_attrs)a do
      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, job} = ORM.find(Job, job.id, preload: :communities)
      assert job.communities |> length == 1

      assert exist_in?(community, job.communities)

      {:ok, _} = CMS.mirror_article(:job, job.id, community2.id)

      {:ok, job} = ORM.find(Job, job.id, preload: :communities)
      assert job.communities |> length == 2

      assert exist_in?(community, job.communities)
      assert exist_in?(community2, job.communities)
    end

    test "job can be mirror to other community with tags",
         ~m(user community community2 job_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community2, :job, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :job, article_tag_attrs2, user)

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, _} =
        CMS.mirror_article(:job, job.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, job} = ORM.find(Job, job.id, preload: :article_tags)
      assert job.article_tags |> length == 2

      assert exist_in?(article_tag, job.article_tags)
      assert exist_in?(article_tag2, job.article_tags)
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

      assert not exist_in?(community3, job.communities)
    end

    test "job can be unmirror from community with tags",
         ~m(user community community2 community3 job_attrs)a do
      article_tag_attrs2 = mock_attrs(:article_tag)
      article_tag_attrs3 = mock_attrs(:article_tag)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :job, article_tag_attrs2, user)
      {:ok, article_tag3} = CMS.create_article_tag(community3, :job, article_tag_attrs3, user)

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.mirror_article(:job, job.id, community2.id, [article_tag2.id])
      {:ok, _} = CMS.mirror_article(:job, job.id, community3.id, [article_tag3.id])

      {:ok, _} = CMS.unmirror_article(:job, job.id, community3.id)
      {:ok, job} = ORM.find(Job, job.id, preload: :article_tags)

      assert exist_in?(article_tag2, job.article_tags)
      assert not exist_in?(article_tag3, job.article_tags)
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

    test "job can be mirror to home", ~m(community job_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      assert job.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:job, job.id)
      {:ok, job} = ORM.find(Job, job.id, preload: [:original_community, :communities])

      assert job.original_community_id == community.id
      assert job.communities |> length == 2

      assert exist_in?(community, job.communities)
      assert exist_in?(home_community, job.communities)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:job, filter)

      assert exist_in?(job, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:job, filter)

      assert exist_in?(job, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "job can be mirror to home with tags", ~m(community job_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} = CMS.create_article_tag(home_community, :job, article_tag_attrs0, user)

      {:ok, article_tag} = CMS.create_article_tag(home_community, :job, article_tag_attrs, user)

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      assert job.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:job, job.id, [article_tag0.id, article_tag.id])

      {:ok, job} =
        ORM.find(Job, job.id, preload: [:original_community, :communities, :article_tags])

      assert job.original_community_id == community.id
      assert job.communities |> length == 2

      assert exist_in?(community, job.communities)
      assert exist_in?(home_community, job.communities)

      assert job.article_tags |> length == 2
      assert exist_in?(article_tag0, job.article_tags)
      assert exist_in?(article_tag, job.article_tags)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:job, filter)

      assert exist_in?(job, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:job, filter)

      assert exist_in?(job, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "job can be move to blackhole", ~m(community job_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      assert job.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:job, job.id)
      {:ok, job} = ORM.find(Job, job.id, preload: [:original_community, :communities])

      assert job.original_community.id == blackhole_community.id
      assert job.communities |> length == 1

      assert exist_in?(blackhole_community, job.communities)

      filter = %{page: 1, size: 10, community: blackhole_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:job, filter)

      assert exist_in?(job, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "job can be move to blackhole with tags", ~m(community job_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(blackhole_community, :job, article_tag_attrs0, user)

      {:ok, article_tag} =
        CMS.create_article_tag(blackhole_community, :job, article_tag_attrs, user)

      {:ok, job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _} = CMS.set_article_tag(:job, job.id, article_tag0.id)

      assert job.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:job, job.id, [article_tag.id])

      {:ok, job} =
        ORM.find(Job, job.id, preload: [:original_community, :communities, :article_tags])

      assert job.original_community.id == blackhole_community.id
      assert job.communities |> length == 1
      assert job.article_tags |> length == 1

      assert exist_in?(blackhole_community, job.communities)
      assert exist_in?(article_tag, job.article_tags)
    end
  end
end
