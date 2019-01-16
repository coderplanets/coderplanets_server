defmodule MastaniServer.Test.CMS do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS
  alias CMS.Community

  alias Helper.{Certification, ORM}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, category} = db_insert(:category)

    {:ok, ~m(user community category)a}
  end

  describe "[cms tag]" do
    test "create tag with valid data", ~m(community user)a do
      valid_attrs = mock_attrs(:tag)

      {:ok, tag} = CMS.create_tag(community, :post, valid_attrs, user)
      assert tag.title == valid_attrs.title
    end

    test "create tag with non-exsit user fails", ~m(user)a do
      invalid_attrs = mock_attrs(:tag)

      assert {:error, _} =
               CMS.create_tag(%Community{id: non_exsit_id()}, :post, invalid_attrs, user)
    end

    test "create tag with non-exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:tag)

      assert {:error, _} =
               CMS.create_tag(%Community{id: non_exsit_id()}, :post, invalid_attrs, user)
    end
  end

  describe "[cms category]" do
    alias CMS.{Community, Category}

    test "create category with valid attrs", ~m(user)a do
      valid_attrs = mock_attrs(:category, %{user_id: user.id})
      ~m(title raw)a = valid_attrs

      {:ok, category} = CMS.create_category(~m(title raw)a, user)

      assert category.title == valid_attrs.title
    end

    test "create category with same title fails", ~m(user)a do
      valid_attrs = mock_attrs(:category, %{user_id: user.id})
      ~m(title raw)a = valid_attrs

      assert {:ok, _} = CMS.create_category(~m(title raw)a, user)
      assert {:error, _} = CMS.create_category(~m(title)a, user)
    end

    test "update category with valid attrs", ~m(user)a do
      valid_attrs = mock_attrs(:category, %{user_id: user.id})
      ~m(title raw)a = valid_attrs

      {:ok, category} = CMS.create_category(~m(title raw)a, user)

      assert category.title == valid_attrs.title
      {:ok, updated} = CMS.update_category(%Category{id: category.id, title: "new title"})

      assert updated.title == "new title"
    end

    test "update title to existing title fails", ~m(user)a do
      valid_attrs = mock_attrs(:category, %{user_id: user.id})
      ~m(title raw)a = valid_attrs

      {:ok, category} = CMS.create_category(~m(title raw)a, user)

      new_category_attrs = %{title: "category2 title", raw: "category2 title"}
      {:ok, category2} = CMS.create_category(new_category_attrs, user)

      {:error, _} = CMS.update_category(%Category{id: category.id, title: category2.title})
    end

    test "can set a category to a community", ~m(community category)a do
      {:ok, _} = CMS.set_category(community, category)

      {:ok, found_community} = ORM.find(Community, community.id, preload: :categories)
      {:ok, found_category} = ORM.find(Category, category.id, preload: :communities)

      assoc_categroies = found_community.categories |> Enum.map(& &1.id)
      assoc_communities = found_category.communities |> Enum.map(& &1.id)

      assert category.id in assoc_categroies
      assert community.id in assoc_communities
    end

    test "can unset a category to a community", ~m(community category)a do
      {:ok, _} = CMS.set_category(community, category)
      CMS.unset_category(community, category)

      {:ok, found_community} = ORM.find(Community, community.id, preload: :categories)
      {:ok, found_category} = ORM.find(Category, category.id, preload: :communities)

      assoc_categroies = found_community.categories |> Enum.map(& &1.id)
      assoc_communities = found_category.communities |> Enum.map(& &1.id)

      assert category.id not in assoc_categroies
      assert community.id not in assoc_communities
    end
  end

  # this logic is move to resolver
  # describe "[cms community]" do
  # test "create a community with a existing user", ~m(user)a do
  # community_args = %{
  # title: "elixir community",
  # desc: "function pragraming for everyone",
  # user_id: user.id,
  # raw: "elixir",
  # logo: "http: ..."
  # }

  # assert {:error, _} = ORM.find_by(CMS.Community, title: "elixir community")
  # {:ok, community} = CMS.create_community(community_args)
  # assert community.title == community_args.title
  # end

  # test "create a community with a empty title fails", ~m(user)a do
  # invalid_community_args = %{
  # title: "",
  # desc: "function pragraming for everyone",
  # user_id: user.id
  # }

  # assert {:error, %Ecto.Changeset{}} = CMS.create_community(invalid_community_args)
  # end

  # test "create a community with a non-exist user fails" do
  # community_args = %{
  # title: "elixir community",
  # desc: "function pragraming for everyone",
  # user_id: 10000
  # }

  # assert {:error, _} = CMS.create_community(community_args)
  # end
  # end

  describe "[cms community thread]" do
    alias CMS.Community

    test "can create thread to a community" do
      title = "post"
      raw = "POST"
      {:ok, thread} = CMS.create_thread(~m(title raw)a)
      assert thread.title == title
    end

    test "create thread with exsit title fails" do
      title = "POST"
      raw = title
      {:ok, _} = CMS.create_thread(~m(title raw)a)
      assert {:error, _error} = CMS.create_thread(~m(title raw)a)
    end

    test "can set a thread to community", ~m(community)a do
      title = "POST"
      raw = title
      {:ok, thread} = CMS.create_thread(~m(title raw)a)
      {:ok, ret_community} = CMS.set_thread(community, thread)

      assert ret_community.id == community.id
    end
  end

  describe "[cms community editors]" do
    alias CMS.{Community, CommunityEditor}

    test "can add editor to a community, editor has default passport", ~m(user community)a do
      title = "chief editor"

      {:ok, _} = CMS.set_editor(community, title, user)

      related_rules = Certification.passport_rules(cms: title)

      {:ok, editor} = CommunityEditor |> ORM.find_by(user_id: user.id)
      {:ok, user_passport} = CMS.get_passport(user)

      assert editor.user_id == user.id
      assert editor.community_id == community.id
      assert Map.equal?(related_rules, user_passport)
    end

    test "user can get paged-editors of a community", ~m(community)a do
      {:ok, users} = db_insert_multi(:user, 25)
      title = "chief editor"

      Enum.each(
        users,
        &CMS.set_editor(community, title, %User{id: &1.id})
      )

      filter = %{page: 1, size: 10}
      {:ok, results} = CMS.community_members(:editors, %Community{id: community.id}, filter)

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 25
    end
  end

  describe "[cms community subscribe]" do
    alias CMS.Community

    test "user can subscribe a community", ~m(user community)a do
      {:ok, record} = CMS.subscribe_community(community, user)
      assert community.id == record.id
    end

    test "user can get paged-subscribers of a community", ~m(community)a do
      {:ok, users} = db_insert_multi(:user, 25)

      Enum.each(
        users,
        &CMS.subscribe_community(community, %User{id: &1.id})
      )

      {:ok, results} =
        CMS.community_members(:subscribers, %Community{id: community.id}, %{page: 1, size: 10})

      assert results |> is_valid_pagination?(:raw)
    end
  end
end
