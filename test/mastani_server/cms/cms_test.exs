defmodule MastaniServer.CMSTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  alias MastaniServer.CMS
  alias MastaniServer.Accounts
  alias MastaniServer.Repo

  @mock_user %{
    username: "mydearxym",
    nickname: "simon",
    bio: "bio",
    company: "infomedia"
  }

  @mock_user2 %{
    username: "other_user",
    nickname: "simon",
    bio: "bio",
    company: "infomedia"
  }

  @mock_community %{
    title: "fake_community",
    desc: "fake community desc",
    author: mock(:user)
  }

  @mock_post %{
    title: Faker.Lorem.Shakespeare.king_richard_iii(),
    body: Faker.Lorem.sentence(%Range{first: 80, last: 120}),
    digest: "fake digest",
    length: 100,
    community: @mock_community.title
  }

  # alias MastaniServer.CMS
  setup do
    db_insert(:user, @mock_user)
    db_insert(:user, @mock_user2)
    db_insert(:community, @mock_community)
    :ok
  end

  describe "cms reaction" do
    test "favorite and undo favorite reaction to post" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @mock_post)

      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user.id)
      {:ok, reaction_users} = CMS.reaction_users(:post, :favorite, post.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      # undo test
      {:ok, _} = CMS.undo_reaction(:post, :favorite, post.id, user.id)
      {:ok, reaction_users2} = CMS.reaction_users(:post, :favorite, post.id, %{page: 1, size: 1})
      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end
  end

  describe "cms_post" do
    test "create post with valid attrs" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)

      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @mock_post)
      assert post.title == @mock_post.title
    end

    test "create post with on exsit community fails" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)
      body = Faker.Lorem.sentence(%Range{first: 80, last: 120})

      invalid_attrs = %{
        title: Faker.Lorem.Shakespeare.king_richard_iii(),
        body: body,
        digest: String.slice(body, 1, 150),
        length: String.length(body),
        community: "non-exsit community"
      }

      assert {:error, _} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, invalid_attrs)
    end

    # TODO: update post
    test "update a post by post's author" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @mock_post)

      new_attrs = %{
        title: "update title"
      }

      current_user = %Accounts.User{id: user.id}
      {:ok, update_post} = CMS.update_content(:post, :self, post.id, current_user, new_attrs)

      assert update_post.title == new_attrs.title
    end

    test "update a post by other user fails" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)
      other_user = Repo.get_by(Accounts.User, username: @mock_user2.username)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @mock_post)

      new_attrs = %{
        title: "update title"
      }

      current_user = %Accounts.User{id: other_user.id}
      result = CMS.update_content(:post, :self, post.id, current_user, new_attrs)

      assert {:error, _} = result
    end

    test "delete post by post's author" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @mock_post)
      {:ok, deleted_post} = CMS.delete_content(:post, :self, post.id, %Accounts.User{id: user.id})

      assert deleted_post.id == post.id
      assert nil == Repo.get(CMS.Post, post.id)
    end

    test "delete post by the other user(not the post author) fails" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)
      other_user = Repo.get_by(Accounts.User, username: @mock_user2.username)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @mock_post)

      current_user = %Accounts.User{id: other_user.id}
      assert {:error, _} = CMS.delete_content(:post, :self, post.id, current_user)
    end
  end

  describe "cms_tags" do
    test "create tag with valid data" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)

      valid_attrs = %{
        title: "fake_tag",
        part: "POST",
        color: "RED",
        community: @mock_community.title,
        user_id: user.id
      }

      {:ok, tag} = CMS.create_tag(:post, valid_attrs)
      assert tag.title == valid_attrs.title
    end

    test "create tag with non-exsit user fails" do
      invalid_attrs = %{
        title: "fake_tag",
        part: "POST",
        color: "RED",
        community: @mock_community.title,
        user_id: 100_000
      }

      assert {:error, %Ecto.Changeset{}} = CMS.create_tag(:post, invalid_attrs)
    end

    test "create tag with non-exsit community fails" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)

      invalid_attrs = %{
        title: "fake_tag",
        part: "POST",
        color: "RED",
        community: "not exsit",
        user_id: user.id
      }

      assert {:error, _} = CMS.create_tag(:post, invalid_attrs)
    end
  end

  describe "cms_community" do
    test "create a community with a existing user" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)

      community_attr = %{
        title: "elixir community",
        desc: "function pragraming for everyone",
        user_id: user.id
      }

      assert Repo.get_by(CMS.Community, title: "elixir community") == nil
      {:ok, community} = CMS.create_community(community_attr)

      assert community.title == community_attr.title
    end

    test "create a community with a empty title fails" do
      user = Repo.get_by(Accounts.User, username: @mock_user.username)

      invalid_community_attr = %{
        title: "",
        desc: "function pragraming for everyone",
        user_id: user.id
      }

      assert {:error, %Ecto.Changeset{}} = CMS.create_community(invalid_community_attr)
    end

    test "create a community with a non-exist user fails" do
      community_attr = %{
        title: "elixir community",
        desc: "function pragraming for everyone",
        user_id: 10000
      }

      assert {:error, _} = CMS.create_community(community_attr)
    end
  end
end
