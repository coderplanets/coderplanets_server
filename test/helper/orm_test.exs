defmodule GroupherServer.Test.Helper.ORMTest do
  use GroupherServerWeb.ConnCase, async: true

  # TODO import Service.Utils move both helper and github
  import GroupherServer.Support.Factory

  alias GroupherServer.CMS.{Post, Author}
  alias GroupherServer.Accounts.User
  alias Helper.ORM

  @posts_count 20
  @post_clauses %{title: "hello groupher"}

  setup do
    # TODO: token
    db_insert_multi(:post, @posts_count)
    {:ok, post} = db_insert(:post, @post_clauses)

    {:ok, post: post}
  end

  # def send_email(to \\ "someone") do 
  #   IO.inspect "send email.. #{to}"
  # end 

  # describe "orm hooks" do
  #   test "create hooks" do
  #     user_attrs = mock_attrs(:user)
  #     user_attrs2 = mock_attrs(:user)

  #     {:ok, _} = ORM.create(User, user_attrs, %{after_success: [&send_email/1, ["me"] ]})
  #     {:ok, _} = ORM.create(User, user_attrs2, %{after_success: &send_email/0})

  #     ORM.create(User, user_attrs, %{after_success: [&Email.notify_admin/2, [user, :new_register] ]  })

  #     true
  #   end 
  # end

  describe "[find/x find_by]" do
    test "find/2 should work, and not preload fields", %{post: post} do
      {:ok, found} = ORM.find(Post, post.id)

      assert found.id == post.id
      assert %Ecto.Association.NotLoaded{} = found.author
      assert %Ecto.Association.NotLoaded{} = found.comments
      assert %Ecto.Association.NotLoaded{} = found.favorites
    end

    test "find/2 fails with {:error, reason} style" do
      result = ORM.find(Post, 15_982_398_614)

      assert {:error, _} = result
    end

    test "find/3 with preload can preload one field", %{post: post} do
      {:ok, found} = ORM.find(Post, post.id, preload: :author)

      assert found.id == post.id
      assert %Author{} = found.author
    end

    test "find/3 with preload can preload muilt fields", %{post: post} do
      {:ok, found} = ORM.find(Post, post.id, preload: [:author, :comments, :communities])
      # IO.inspect found
      assert %Author{} = found.author
      assert %Ecto.Association.NotLoaded{} != found.comments
      assert %Ecto.Association.NotLoaded{} != found.communities
    end

    test "find/3 with preload can preload nested field", %{post: post} do
      {:ok, found} = ORM.find(Post, post.id, preload: [author: :user])

      assert %Author{} = found.author
      assert %User{} = found.author.user
    end

    test "find_by/2 should find a target by given clauses" do
      {:ok, found} = ORM.find_by(Post, @post_clauses)

      assert found.title == @post_clauses.title
    end
  end

  test "count should work" do
    assert @posts_count + 1 == ORM.count(Post)
  end
end
