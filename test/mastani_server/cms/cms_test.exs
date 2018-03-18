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
      invalid_attrs = mock_attrs(:post, %{community: "non-exsit community"})

      assert {:error, _} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, invalid_attrs)
    end
  end

  describe "cms_tags" do
    test "create tag with valid data" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)
      valid_attrs = mock_attrs(:tag, %{user_id: user.id, community: @valid_community.title})

      {:ok, tag} = CMS.create_tag(:post, valid_attrs)
      assert tag.title == valid_attrs.title
    end

    test "create tag with non-exsit user fails" do
      invalid_attrs = mock_attrs(:tag, %{user_id: 100_086, community: @valid_community.title})

      assert {:error, %Ecto.Changeset{}} = CMS.create_tag(:post, invalid_attrs)
    end

    test "create tag with non-exsit community fails" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)
      invalid_attrs = mock_attrs(:tag, %{user_id: user.id, community: "not exsit"})

      assert {:error, _} = CMS.create_tag(:post, invalid_attrs)
    end
  end

  describe "cms_community" do
    test "create a community with a existing user" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)

      community_args = %{
        title: "elixir community",
        desc: "function pragraming for everyone",
        user_id: user.id
      }

      assert Repo.get_by(CMS.Community, title: "elixir community") == nil
      {:ok, community} = CMS.create_community(community_args)
      assert community.title == community_args.title
    end

    test "create a community with a empty title fails" do
      user = Repo.get_by(Accounts.User, username: @valid_user.username)

      invalid_community_args = %{
        title: "",
        desc: "function pragraming for everyone",
        user_id: user.id
      }

      assert {:error, %Ecto.Changeset{}} = CMS.create_community(invalid_community_args)
    end

    test "create a community with a non-exist user fails" do
      community_args = %{
        title: "elixir community",
        desc: "function pragraming for everyone",
        user_id: 10000
      }

      assert {:error, _} = CMS.create_community(community_args)
    end
  end
end
