defmodule MastaniServer.Test.CMSTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import ShortMaps

  alias MastaniServer.{CMS, Accounts}
  alias Helper.ORM

  @valid_user mock_attrs(:user)
  @valid_user2 mock_attrs(:user)
  @valid_community mock_attrs(:community)
  @valid_post mock_attrs(:post, %{community: @valid_community.title})

  setup do
    {:ok, user} = db_insert(:user, @valid_user)
    db_insert(:user, @valid_user2)
    {:ok, community} = db_insert(:community, @valid_community)

    {:ok, ~m(user community)a}
  end

  describe "[cms post]" do
    test "create post with valid attrs", ~m(user)a do
      assert {:error, _} = ORM.find_by(CMS.Author, user_id: user.id)

      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @valid_post)
      assert post.title == @valid_post.title
    end

    test "add user to cms authors, if the user is not exsit in cms authors", ~m(user)a do
      assert {:error, _} = ORM.find_by(CMS.Author, user_id: user.id)

      {:ok, _} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @valid_post)
      {:ok, author} = ORM.find_by(CMS.Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create post with on exsit community fails" do
      {:ok, user} = ORM.find_by(Accounts.User, nickname: @valid_user.nickname)
      invalid_attrs = mock_attrs(:post, %{community: "non-exsit community"})

      assert {:error, _} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, invalid_attrs)
    end
  end

  describe "[cms tag]" do
    test "create tag with valid data", ~m(community)a do
      {:ok, user} = ORM.find_by(Accounts.User, nickname: @valid_user.nickname)
      valid_attrs = mock_attrs(:tag, %{user_id: user.id, community: community.title})

      {:ok, tag} = CMS.create_tag(:post, valid_attrs)
      assert tag.title == valid_attrs.title
    end

    test "create tag with non-exsit user fails", ~m(community)a do
      invalid_attrs = mock_attrs(:tag, %{user_id: 100_086, community: community.title})

      assert {:error, %Ecto.Changeset{}} = CMS.create_tag(:post, invalid_attrs)
    end

    test "create tag with non-exsit community fails" do
      {:ok, user} = ORM.find_by(Accounts.User, nickname: @valid_user.nickname)
      invalid_attrs = mock_attrs(:tag, %{user_id: user.id, community: "not exsit"})

      assert {:error, _} = CMS.create_tag(:post, invalid_attrs)
    end
  end

  describe "[cms community]" do
    test "create a community with a existing user" do
      {:ok, user} = ORM.find_by(Accounts.User, nickname: @valid_user.nickname)

      community_args = %{
        title: "elixir community",
        desc: "function pragraming for everyone",
        user_id: user.id
      }

      assert {:error, _} = ORM.find_by(CMS.Community, title: "elixir community")
      {:ok, community} = CMS.create_community(community_args)
      assert community.title == community_args.title
    end

    test "create a community with a empty title fails" do
      {:ok, user} = ORM.find_by(Accounts.User, nickname: @valid_user.nickname)

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

  describe "[cms community subscribe]" do
    test "user can subscribe a community", ~m(user community)a do
      {:ok, subscriber} =
        CMS.subscribe_community(%Accounts.User{id: user.id}, %CMS.Community{id: community.id})

      assert user.id == subscriber.user_id
      assert community.id == subscriber.community_id
    end
  end
end
