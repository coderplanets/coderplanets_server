defmodule GroupherServer.Test.CMS.ContentFlags do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.CMS

  alias CMS.{
    PostCommunityFlag,
    RepoCommunityFlag,
    JobCommunityFlag,
    VideoCommunityFlag
  }

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, post} = CMS.create_content(community, :post, mock_attrs(:post), user)
    {:ok, job} = CMS.create_content(community, :job, mock_attrs(:job), user)
    {:ok, video} = CMS.create_content(community, :video, mock_attrs(:video), user)
    {:ok, repo} = CMS.create_content(community, :repo, mock_attrs(:repo), user)

    {:ok, ~m(user community post job video repo)a}
  end

  describe "[cms post flag]" do
    test "user can set trash flag on post based on community", ~m(community post)a do
      community_id = community.id
      post_id = post.id
      {:ok, found} = PostCommunityFlag |> ORM.find_by(~m(post_id community_id)a)
      assert found.trash == false

      CMS.set_community_flags(community, post, %{trash: true})

      {:ok, found} = PostCommunityFlag |> ORM.find_by(~m(post_id community_id)a)

      assert found.trash == true
      assert found.post_id == post.id
      assert found.community_id == community.id
    end

    # TODO: set twice .. staff
  end

  describe "[cms job flag]" do
    test "user can set trash flag on job", ~m(community job)a do
      community_id = community.id
      job_id = job.id

      {:ok, found} = JobCommunityFlag |> ORM.find_by(~m(job_id community_id)a)
      assert found.trash == false

      CMS.set_community_flags(community, job, %{trash: true})

      {:ok, found} = JobCommunityFlag |> ORM.find_by(~m(job_id community_id)a)

      assert found.trash == true
      assert found.job_id == job.id
      assert found.community_id == community.id
    end
  end

  describe "[cms video flag]" do
    test "user can set trash flag on a video", ~m(community video)a do
      community_id = community.id
      video_id = video.id

      {:ok, found} = VideoCommunityFlag |> ORM.find_by(~m(video_id community_id)a)
      assert found.trash == false

      CMS.set_community_flags(community, video, %{trash: true})

      {:ok, found} = VideoCommunityFlag |> ORM.find_by(~m(video_id community_id)a)

      assert found.trash == true
      assert found.video_id == video.id
      assert found.community_id == community.id
    end
  end

  describe "[cms repo flag]" do
    test "user can set trash flag on repo", ~m(community repo)a do
      community_id = community.id
      repo_id = repo.id

      {:ok, found} = RepoCommunityFlag |> ORM.find_by(~m(repo_id community_id)a)
      assert found.trash == false

      CMS.set_community_flags(community, repo, %{trash: true})

      {:ok, found} = RepoCommunityFlag |> ORM.find_by(~m(repo_id community_id)a)

      assert found.trash == true
      assert found.repo_id == repo.id
      assert found.community_id == community.id
    end
  end
end
