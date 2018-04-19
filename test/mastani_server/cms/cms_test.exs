defmodule MastaniServer.Test.CMSTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Test.AssertHelper
  import MastaniServer.Factory
  import ShortMaps

  alias MastaniServer.{CMS, Accounts}
  alias Helper.{ORM, Certification}

  @valid_user mock_attrs(:user)
  @valid_user2 mock_attrs(:user)
  @valid_community mock_attrs(:community)
  @valid_post mock_attrs(:post, %{community: @valid_community.title})

  setup do
    {:ok, user} = db_insert(:user, @valid_user)
    {:ok, user2} = db_insert(:user)
    db_insert(:user, @valid_user2)
    {:ok, community} = db_insert(:community, @valid_community)

    {:ok, ~m(user user2 community)a}
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
        user_id: user.id,
        raw: "elixir",
        category: "编程语言",
        logo: "http: ..."
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

  describe "[cms community thread]" do
    test "can create thread" do
      title = "post"
      raw = title
      {:ok, thread} = CMS.create_thread(~m(title raw)a)
      assert thread.title == title
    end

    test "create thread with exsit title fails" do
      title = "post"
      raw = title
      {:ok, _} = CMS.create_thread(~m(title raw)a)
      assert {:error, _error} = CMS.create_thread(~m(title raw)a)
    end

    test "can add a thread to community", ~m(community)a do
      title = "post"
      raw = title
      {:ok, thread} = CMS.create_thread(~m(title raw)a)
      thread_id = thread.id
      community_id = community.id
      {:ok, ret_community} = CMS.add_thread_to_community(~m(thread_id community_id)a)
      assert ret_community.id == community.id
    end
  end

  describe "[cms community editors]" do
    test "can add editor to a community, editor has default passport", ~m(user community)a do
      title = "chief editor"

      {:ok, _} =
        CMS.add_editor(%Accounts.User{id: user.id}, %CMS.Community{id: community.id}, title)

      related_rules = Certification.passport_rules(cms: title)

      {:ok, editor} = CMS.CommunityEditor |> ORM.find_by(user_id: user.id)
      {:ok, user_passport} = CMS.get_passport(%Accounts.User{id: user.id})

      assert editor.user_id == user.id
      assert editor.community_id == community.id
      assert Map.equal?(related_rules, user_passport)
    end

    test "user can get paged-editors of a community", ~m(community)a do
      {:ok, users} = db_insert_multi(:user, 25)
      title = "chief editor"

      Enum.each(
        users,
        &CMS.add_editor(%Accounts.User{id: &1.id}, %CMS.Community{id: community.id}, title)
      )

      {:ok, results} =
        CMS.community_members(:editors, %CMS.Community{id: community.id}, %{page: 1, size: 10})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_entries == 25
    end
  end

  describe "[cms community subscribe]" do
    test "user can subscribe a community", ~m(user community)a do
      {:ok, record} =
        CMS.subscribe_community(%Accounts.User{id: user.id}, %CMS.Community{id: community.id})

      assert community.id == record.id
    end

    test "user can get paged-subscribers of a community", ~m(community)a do
      {:ok, users} = db_insert_multi(:user, 25)

      Enum.each(
        users,
        &CMS.subscribe_community(%Accounts.User{id: &1.id}, %CMS.Community{id: community.id})
      )

      {:ok, results} =
        CMS.community_members(:subscribers, %CMS.Community{id: community.id}, %{page: 1, size: 10})

      assert results |> is_valid_pagination?(:raw)
    end
  end
end
