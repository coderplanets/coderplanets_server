defmodule MastaniServer.Test.ContentFlagsTest do
  use MastaniServer.TestTools

  alias MastaniServer.CMS
  alias CMS.{Post, Video, Repo}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, video} = db_insert(:video)
    {:ok, repo} = db_insert(:repo)

    {:ok, ~m(user post video repo)a}
  end

  describe "[cms post flag]" do
    test "user can set pin flag on a post", ~m(user post)a do
      {:ok, updated} = CMS.set_flag(Post, post.id, %{pin: true}, user)
      assert updated.pin == true

      {:ok, updated} = CMS.set_flag(Post, post.id, %{pin: false}, user)
      assert updated.pin == false
    end

    test "user can set trash flag on a post", ~m(user post)a do
      {:ok, updated} = CMS.set_flag(Post, post.id, %{trash: true}, user)
      assert updated.trash == true

      {:ok, updated} = CMS.set_flag(Post, post.id, %{trash: false}, user)
      assert updated.trash == false
    end
  end

  describe "[cms video flag]" do
    test "user can set pin flag on a video", ~m(user video)a do
      {:ok, updated} = CMS.set_flag(Video, video.id, %{pin: true}, user)
      assert updated.pin == true

      {:ok, updated} = CMS.set_flag(Video, video.id, %{pin: false}, user)
      assert updated.pin == false
    end

    test "user can set trash flag on a video", ~m(user video)a do
      {:ok, updated} = CMS.set_flag(Video, video.id, %{trash: true}, user)
      assert updated.trash == true

      {:ok, updated} = CMS.set_flag(Video, video.id, %{trash: false}, user)
      assert updated.trash == false
    end
  end

  describe "[cms repo flag]" do
    test "user can set pin flag on a repo", ~m(user repo)a do
      {:ok, updated} = CMS.set_flag(Repo, repo.id, %{pin: true}, user)
      assert updated.pin == true

      {:ok, updated} = CMS.set_flag(Repo, repo.id, %{pin: false}, user)
      assert updated.pin == false
    end

    test "user can set trash flag on a repo", ~m(user repo)a do
      {:ok, updated} = CMS.set_flag(Repo, repo.id, %{trash: true}, user)
      assert updated.trash == true

      {:ok, updated} = CMS.set_flag(Repo, repo.id, %{trash: false}, user)
      assert updated.trash == false
    end
  end
end
