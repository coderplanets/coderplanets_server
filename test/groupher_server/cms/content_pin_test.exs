defmodule GroupherServer.Test.CMS.ContentsPin do
  use GroupherServer.TestTools

  # alias Helper.ORM
  alias GroupherServer.CMS

  # alias CMS.{
  # Post,
  # PinedPost,
  # Job,
  # PinedJob,
  # }

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, post} = CMS.create_content(community, :post, mock_attrs(:post), user)
    {:ok, job} = CMS.create_content(community, :job, mock_attrs(:job), user)
    {:ok, repo} = CMS.create_content(community, :repo, mock_attrs(:repo), user)

    {:ok, ~m(user community post job repo)a}
  end

  describe "[cms post pin]" do
    test "can pin a post", ~m(community post)a do
      {:ok, pined_post} = CMS.pin_content(post, community, "posts")

      assert pined_post.id == post.id
    end

    test "can undo pin to a post", ~m(community post)a do
      {:ok, pined_post} = CMS.pin_content(post, community, "posts")
      assert pined_post.id == post.id

      assert {:ok, unpined} = CMS.undo_pin_content(post, community, "posts")
      assert unpined.id == post.id
    end
  end

  describe "[cms job pin]" do
    test "can pin a job", ~m(community job)a do
      {:ok, pined_job} = CMS.pin_content(job, community)

      assert pined_job.id == job.id
    end

    test "can undo pin to a job", ~m(community job)a do
      {:ok, pined_job} = CMS.pin_content(job, community)
      assert pined_job.id == job.id

      assert {:ok, unpined} = CMS.undo_pin_content(job, community)
      assert unpined.id == job.id
    end
  end

  describe "[cms repo pin]" do
    test "can pin a repo", ~m(community repo)a do
      {:ok, pined_repo} = CMS.pin_content(repo, community)

      assert pined_repo.id == repo.id
    end

    test "can undo pin to a repo", ~m(community repo)a do
      {:ok, pined_repo} = CMS.pin_content(repo, community)
      assert pined_repo.id == repo.id

      assert {:ok, unpined} = CMS.undo_pin_content(repo, community)
      assert unpined.id == repo.id
    end
  end
end
