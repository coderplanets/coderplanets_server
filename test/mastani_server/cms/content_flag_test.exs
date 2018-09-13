defmodule MastaniServer.Test.ContentFlags do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  # alias CMS.{Post, PostCommunityFlags, Repo, Video}
  alias CMS.{Post, PostCommunityFlags}
  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, video} = db_insert(:video)
    {:ok, repo} = db_insert(:repo)

    {:ok, ~m(user post video repo)a}
  end

  describe "[cms post flag]" do
    test "user can set pin flag on post based on community", ~m(post)a do
      community1_id = post.communities |> List.first() |> Map.get(:id)
      CMS.set_community_flags(%Post{id: post.id}, community1_id, %{pin: true})

      {:ok, found} =
        ORM.find_by(PostCommunityFlags, %{post_id: post.id, community_id: community1_id})

      assert found.pin == true
      assert found.post_id == post.id
      assert found.community_id == community1_id
    end

    # TODO: set twice .. staff
  end

  # describe "[cms video flag]" do
  # test "user can set pin flag on a video", ~m(user video)a do
  # true
  # end

  # test "user can set trash flag on a video", ~m(user video)a do
  # true
  # end
  # end

  # describe "[cms repo flag]" do
  # test "user can set pin flag on a repo", ~m(user repo)a do
  # true
  # end

  # test "user can set trash flag on a repo", ~m(user repo)a do
  # true
  # end
  # end
end
