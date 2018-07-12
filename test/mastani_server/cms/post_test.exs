defmodule MastaniServer.Test.PostTest do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS
  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user post_attrs)a}
  end

  describe "[cms post curd]" do
    alias CMS.Author

    test "can create post with valid attrs", ~m(user post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, post} = CMS.create_content(:post, %User{id: user.id}, post_attrs)
      assert post.title == post_attrs.title
    end

    test "add user to cms authors, if the user is not exsit in cms authors",
         ~m(user post_attrs)a do
      assert {:error, _} = ORM.find_by(CMS.Author, user_id: user.id)

      {:ok, _} = CMS.create_content(:post, %User{id: user.id}, post_attrs)
      {:ok, author} = ORM.find_by(CMS.Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create post with on exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:post, %{community_id: non_exsit_id()})

      assert {:error, _} = CMS.create_content(:post, %User{id: user.id}, invalid_attrs)
    end
  end
end
