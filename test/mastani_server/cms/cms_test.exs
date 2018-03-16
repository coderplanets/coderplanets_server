defmodule MastaniServer.CMSTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  alias MastaniServer.CMS
  alias MastaniServer.Accounts
  alias MastaniServer.Repo

  @valid_user mock_attrs(:user)
  @valid_user2 mock_attrs(:user)
  @valid_community mock_attrs(:community)
  @valid_post mock_attrs(:post, %{community: @valid_community.title})

  # alias MastaniServer.CMS
  setup do
    db_insert(:user, @valid_user)
    db_insert(:user, @valid_user2)
    db_insert(:community, @valid_community)
    :ok
  end

  describe "cms_post" do
    test "create post with valid attrs" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)
      assert nil == Repo.get_by(CMS.Author, user_id: user.id)

      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @valid_post)
      assert post.title == @valid_post.title
    end

    test "add user to cms authors, if the user is not exsit in cms authors" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)
      assert nil == Repo.get_by(CMS.Author, user_id: user.id)

      {:ok, _} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @valid_post)
      author = Repo.get_by(CMS.Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create post with on exsit community fails" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)
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
      user = Repo.get_by(Accounts.User, username: @valid_user.username)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @valid_post)

      new_attrs = %{
        title: "update title"
      }

      current_user = %Accounts.User{id: user.id}
      {:ok, update_post} = CMS.update_content(:post, :self, post.id, current_user, new_attrs)

      assert update_post.title == new_attrs.title
    end

    test "update a post by other user fails" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)
      other_user = Repo.get_by(Accounts.User, username: @valid_user2.username)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @valid_post)

      new_attrs = %{
        title: "update title"
      }

      current_user = %Accounts.User{id: other_user.id}
      result = CMS.update_content(:post, :self, post.id, current_user, new_attrs)

      assert {:error, _} = result
    end

    test "delete post by post's author" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @valid_post)
      {:ok, deleted_post} = CMS.delete_content(:post, :self, post.id, %Accounts.User{id: user.id})

      assert deleted_post.id == post.id
      assert nil == Repo.get(CMS.Post, post.id)
    end

    test "delete post by the other user(not the post author) fails" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)
      other_user = Repo.get_by(Accounts.User, username: @valid_user2.username)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @valid_post)

      current_user = %Accounts.User{id: other_user.id}
      assert {:error, _} = CMS.delete_content(:post, :self, post.id, current_user)
    end

    test "delete a non-exsit post fails" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)

      assert {:error, _} =
               CMS.delete_content(:post, :self, "99999999", %Accounts.User{id: user.id})
    end
  end

  describe "cms_tags" do
    test "create tag with valid data" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)

      valid_attrs = %{
        title: "fake_tag",
        part: "POST",
        color: "RED",
        community: @valid_community.title,
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
        community: @valid_community.title,
        user_id: 100_000
      }

      assert {:error, %Ecto.Changeset{}} = CMS.create_tag(:post, invalid_attrs)
    end

    test "create tag with non-exsit community fails" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)

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
      user = Repo.get_by(Accounts.User, username: @valid_user.username)

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
      user = Repo.get_by(Accounts.User, username: @valid_user.username)

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
