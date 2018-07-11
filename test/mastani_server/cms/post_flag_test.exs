defmodule MastaniServer.Test.PostFlagsTest do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)

    {:ok, ~m(user post)a}
  end

  test "user can set pin flag on a post", ~m(user post)a do
    {:ok, updated} = CMS.set_flag(CMS.Post, post.id, %{pin: true}, user)
    assert updated.pin == true

    {:ok, updated} = CMS.set_flag(CMS.Post, post.id, %{pin: false}, user)
    assert updated.pin == false
  end

  test "user can set trash flag on a post", ~m(user post)a do
    {:ok, updated} = CMS.set_flag(CMS.Post, post.id, %{trash: true}, user)
    assert updated.trash == true

    {:ok, updated} = CMS.set_flag(CMS.Post, post.id, %{trash: false}, user)
    assert updated.trash == false
  end
end
