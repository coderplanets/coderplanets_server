defmodule GroupherServer.Test.Mutation.CMS.Basic do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.{Category, Community, CommunityEditor, Passport, Tag}

  alias Helper.ORM

  setup do
    {:ok, category} = db_insert(:category)
    {:ok, community} = db_insert(:community)
    {:ok, thread} = db_insert(:thread)
    {:ok, tag} = db_insert(:tag, %{community: community})
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn community thread category user tag)a}
  end

  describe "mutation cms category" do
    @create_category_query """
    mutation($title: String!, $raw: String!) {
      createCategory(title: $title, raw: $raw) {
        id
        title
        author {
          id
          nickname
          avatar
        }
      }
    }
    """
    test "auth user can create category", ~m(user)a do
      variables = mock_attrs(:category, %{user_id: user.id})
      rule_conn = simu_conn(:user, cms: %{"category.create" => true})

      created = rule_conn |> mutation_result(@create_category_query, variables, "createCategory")
      # author = created["author"]
      assert created["title"] == variables.title
    end

    @delete_category_query """
    mutation($id: ID!) {
      deleteCategory(id: $id) {
        id
      }
    }
    """
    test "auth user can delete category" do
      {:ok, category} = db_insert(:category)
      rule_conn = simu_conn(:user, cms: %{"category.delete" => true})

      variables = %{id: category.id}
      deleted = rule_conn |> mutation_result(@delete_category_query, variables, "deleteCategory")

      assert deleted["id"] == to_string(category.id)
    end

    @update_category_query """
    mutation($id: ID!, $title: String!) {
      updateCategory(id: $id, title: $title) {
        id
        title
      }
    }
    """
    test "auth user can update  category", ~m(category)a do
      rule_conn = simu_conn(:user, cms: %{"category.update" => true})
      variables = %{id: category.id, title: "new title"}

      updated = rule_conn |> mutation_result(@update_category_query, variables, "updateCategory")
      assert updated["title"] == "new title"
    end

    test "unauth user create category fails", ~m(user user_conn guest_conn)a do
      variables = mock_attrs(:category, %{user_id: user.id})
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@create_category_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@create_category_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@create_category_query, variables, ecode(:passport))
    end

    test "unauth user update category fails", ~m(category user_conn guest_conn)a do
      variables = %{id: category.id, title: "new title"}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@update_category_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@update_category_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@update_category_query, variables, ecode(:passport))
    end

    @set_category_query """
    mutation($categoryId: ID! $communityId: ID!) {
      setCategory(categoryId: $categoryId, communityId: $communityId) {
        id
        title

        categories {
          id
          title
        }
      }
    }
    """
    test "auth user can set a category to a community" do
      {:ok, community} = db_insert(:community)
      {:ok, category} = db_insert(:category)

      rule_conn = simu_conn(:user, cms: %{"category.set" => true})
      variables = %{communityId: community.id, categoryId: category.id}

      rule_conn |> mutation_result(@set_category_query, variables, "setCategory")

      {:ok, found_community} = ORM.find(Community, community.id, preload: :categories)
      {:ok, found_category} = ORM.find(Category, category.id, preload: :communities)

      assoc_categroies = found_community.categories |> Enum.map(& &1.id)
      assoc_communities = found_category.communities |> Enum.map(& &1.id)

      assert category.id in assoc_categroies
      assert community.id in assoc_communities
    end

    @unset_category_query """
    mutation($categoryId: ID! $communityId: ID!) {
      unsetCategory(categoryId: $categoryId, communityId: $communityId) {
        id
        title
      }
    }
    """
    test "auth user can unset a category to a community" do
      {:ok, community} = db_insert(:community)
      {:ok, category} = db_insert(:category)

      {:ok, _} = CMS.set_category(%Community{id: community.id}, %Category{id: category.id})

      rule_conn = simu_conn(:user, cms: %{"category.unset" => true})
      variables = %{communityId: community.id, categoryId: category.id}

      rule_conn |> mutation_result(@unset_category_query, variables, "setCategory")

      {:ok, found_community} = ORM.find(Community, community.id, preload: :categories)
      {:ok, found_category} = ORM.find(Category, category.id, preload: :communities)

      assoc_categroies = found_community.categories |> Enum.map(& &1.id)
      assoc_communities = found_category.communities |> Enum.map(& &1.id)

      assert category.id not in assoc_categroies
      assert community.id not in assoc_communities
    end

    test "unauth user set/unset category fails", ~m(user_conn guest_conn)a do
      {:ok, community} = db_insert(:community)
      {:ok, category} = db_insert(:category)

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})
      variables = %{communityId: community.id, categoryId: category.id}

      assert user_conn |> mutation_get_error?(@set_category_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@set_category_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@set_category_query, variables, ecode(:passport))

      assert user_conn |> mutation_get_error?(@unset_category_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@unset_category_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@unset_category_query, variables, ecode(:passport))
    end
  end

  describe "[mutation cms tag]" do
    @create_tag_query """
    mutation($thread: CmsThread!, $title: String!, $color: RainbowColorEnum!, $communityId: ID!, $topic: String) {
      createTag(thread: $thread, title: $title, color: $color, communityId: $communityId, topic: $topic) {
        id
        title
        color
        thread
        topic {
          title
        }
        community {
          id
          logo
          title
        }
      }
    }
    """
    test "create tag with valid attrs, has default POST thread and default posts topic",
         ~m(community)a do
      variables = mock_attrs(:tag, %{communityId: community.id})

      passport_rules = %{community.title => %{"post.tag.create" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      created = rule_conn |> mutation_result(@create_tag_query, variables, "createTag")
      belong_community = created["community"]

      {:ok, found} = Tag |> ORM.find(created["id"])

      assert created["id"] == to_string(found.id)
      assert found.thread == "post"
      assert created["topic"]["title"] == "posts"
      assert belong_community["id"] == to_string(community.id)
    end

    test "can create some tag on different topic", ~m(community)a do
      variables = mock_attrs(:tag, %{communityId: community.id, topic: "city"})

      passport_rules = %{community.title => %{"post.tag.create" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      created = rule_conn |> mutation_result(@create_tag_query, variables, "createTag")
      assert created["title"] == variables.title
      assert created["topic"]["title"] == "city"

      assert rule_conn
             |> mutation_get_error?(@create_tag_query, variables)

      variables = variables |> Map.merge(%{topic: "radar"})
      created = rule_conn |> mutation_result(@create_tag_query, variables, "createTag")
      assert created["title"] == variables.title
      assert created["topic"]["title"] == "radar"
    end

    test "auth user create duplicate tag fails", ~m(community)a do
      variables = mock_attrs(:tag, %{communityId: community.id})

      passport_rules = %{community.title => %{"post.tag.create" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      assert nil !== rule_conn |> mutation_result(@create_tag_query, variables, "createTag")

      assert rule_conn |> mutation_get_error?(@create_tag_query, variables, ecode(:changeset))
    end

    # TODO: server return 400 wrong status code
    # see https://github.com/absinthe-graphql/absinthe/issues/554
    # test "create with invalid color fails", ~m(community)a do
    # variables = %{
    # title: "title",
    # color: "NON_EXSIT",
    # communityId: community.id,
    # thread: "POST",
    # }
    # passport_rules = %{community.title => %{"post.tag.create" => true}}
    # rule_conn = simu_conn(:user, cms: passport_rules)

    # assert rule_conn |> mutation_get_error?(@create_tag_query, variables)
    # end

    test "unauth user create tag fails", ~m(community user_conn guest_conn)a do
      variables = mock_attrs(:tag, %{communityId: community.id})
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@create_tag_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@create_tag_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@create_tag_query, variables, ecode(:passport))
    end

    @update_tag_query """
    mutation($id: ID!, $color: RainbowColorEnum!, $title: String!, $communityId: ID!) {
      updateTag(id: $id, color: $color, title: $title, communityId: $communityId) {
        id
        title
        color
      }
    }
    """
    test "auth user can update a tag", ~m(tag community)a do
      variables = %{id: tag.id, color: "GREEN", title: "new title", communityId: community.id}

      passport_rules = %{community.title => %{"post.tag.update" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@update_tag_query, variables, "updateTag")

      assert updated["color"] == "green"
      assert updated["title"] == "new title"
    end

    @delete_tag_query """
    mutation($id: ID!, $communityId: ID!){
      deleteTag(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can delete tag", ~m(tag community)a do
      variables = mock_attrs(:tag, %{id: tag.id, communityId: community.id})

      rule_conn = simu_conn(:user, cms: %{tag.community.title => %{"post.tag.delete" => true}})

      deleted = rule_conn |> mutation_result(@delete_tag_query, variables, "deleteTag")

      assert deleted["id"] == to_string(tag.id)
    end

    test "unauth user delete tag fails", ~m(tag user_conn guest_conn)a do
      variables = %{id: tag.id, communityId: tag.community_id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@delete_tag_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@delete_tag_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@delete_tag_query, variables, ecode(:passport))
    end
  end

  describe "[mutation cms community]" do
    @create_community_query """
    mutation($title: String!, $desc: String!, $logo: String!, $raw: String!) {
      createCommunity(title: $title, desc: $desc, logo: $logo, raw: $raw) {
        id
        title
        desc
        author {
          id
        }
      }
    }
    """
    test "create community with valid attrs" do
      rule_conn = simu_conn(:user, cms: %{"community.create" => true})
      variables = mock_attrs(:community)

      created =
        rule_conn |> mutation_result(@create_community_query, variables, "createCommunity")

      {:ok, found} = Community |> ORM.find(created["id"])
      assert created["id"] == to_string(found.id)
    end

    @update_community_query """
    mutation($id: ID!, $title: String, $desc: String, $logo: String, $raw: String) {
      updateCommunity(id: $id, title: $title, desc: $desc, logo: $logo, raw: $raw) {
        id
        title
        desc
      }
    }
    """
    test "update community with valid attrs", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})
      variables = %{id: community.id, title: "new title"}

      updated =
        rule_conn |> mutation_result(@update_community_query, variables, "updateCommunity")

      {:ok, found} = Community |> ORM.find(updated["id"])
      assert updated["id"] == to_string(found.id)
      assert updated["title"] == variables.title
    end

    test "update community with empty attrs return the same", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})
      variables = %{id: community.id}

      updated =
        rule_conn |> mutation_result(@update_community_query, variables, "updateCommunity")

      {:ok, found} = Community |> ORM.find(updated["id"])
      assert updated["id"] == to_string(found.id)
      assert updated["title"] == community.title
    end

    test "unauth user create community fails", ~m(user_conn guest_conn)a do
      variables = mock_attrs(:community)
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn
             |> mutation_get_error?(@create_community_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@create_community_query, variables, ecode(:account_login))

      assert rule_conn
             |> mutation_get_error?(@create_community_query, variables, ecode(:passport))
    end

    test "create duplicated community fails", %{community: community} do
      variables = mock_attrs(:community, %{title: community.title, desc: community.desc})
      rule_conn = simu_conn(:user, cms: %{"community.create" => true})

      assert rule_conn
             |> mutation_get_error?(@create_community_query, variables, ecode(:changeset))
    end

    @delete_community_query """
    mutation($id: ID!){
      deleteCommunity(id: $id) {
        id
      }
    }
    """
    test "auth user can delete community", ~m(community)a do
      variables = %{id: community.id}
      rule_conn = simu_conn(:user, cms: %{"community.delete" => true})

      deleted =
        rule_conn |> mutation_result(@delete_community_query, variables, "deleteCommunity")

      assert deleted["id"] == to_string(community.id)
      assert {:error, _} = ORM.find(Community, community.id)
    end

    test "unauth user delete community fails", ~m(user_conn guest_conn)a do
      variables = mock_attrs(:community)
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn
             |> mutation_get_error?(@create_community_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@create_community_query, variables, ecode(:account_login))

      assert rule_conn
             |> mutation_get_error?(@create_community_query, variables, ecode(:passport))
    end

    test "delete non-exist community fails" do
      rule_conn = simu_conn(:user, cms: %{"community.delete" => true})
      assert rule_conn |> mutation_get_error?(@delete_community_query, %{id: non_exsit_id()})
    end
  end

  describe "[mutation cms thread]" do
    @query """
    mutation($title: String!, $raw: String!){
      createThread(title: $title, raw: $raw) {
        title
      }
    }
    """
    test "auth user can create thread", ~m(user)a do
      title = "post"
      raw = "POST"
      variables = ~m(title raw)a

      passport_rules = %{"thread.create" => true}
      rule_conn = simu_conn(:user, user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "createThread")

      assert result["title"] == title
    end

    test "unauth user create thread fails", ~m(user_conn guest_conn)a do
      title = "psot"
      raw = "POST"
      variables = ~m(title raw)a
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($communityId: ID!, $threadId: ID!){
      setThread(communityId: $communityId, threadId: $threadId) {
        id
        threads {
          title
        }
      }
    }
    """
    test "auth user can add thread to community", ~m(user community)a do
      title = "psot"
      raw = title
      {:ok, thread} = CMS.create_thread(~m(title raw)a)
      variables = %{threadId: thread.id, communityId: community.id}

      passport_rules = %{community.title => %{"thread.set" => true}}
      rule_conn = simu_conn(:user, user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "setThread")

      assert result["threads"] |> List.first() |> Map.get("title") == title
      assert result["id"] == to_string(community.id)
    end

    @query """
    mutation($communityId: ID!, $threadId: ID!){
      unsetThread(communityId: $communityId, threadId: $threadId) {
        id
        threads {
          title
        }
      }
    }
    """
    test "auth user can remove thread from community", ~m(user community thread)a do
      CMS.set_thread(community, thread)
      {:ok, found_community} = Community |> ORM.find(community.id, preload: :threads)

      assert found_community.threads |> Enum.any?(&(&1.thread_id == thread.id))
      variables = %{threadId: thread.id, communityId: community.id}

      passport_rules = %{community.title => %{"thread.unset" => true}}
      rule_conn = simu_conn(:user, user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "unsetThread")
      assert Enum.empty?(result["threads"])
    end
  end

  describe "[mutation cms editors]" do
    @set_editor_query """
    mutation($communityId: ID!, $userId: ID!, $title: String!){
      setEditor(communityId: $communityId, userId: $userId, title: $title) {
        id
      }
    }
    """
    test "auth user can set editor to community", ~m(user community)a do
      title = "chief editor"
      variables = %{userId: user.id, communityId: community.id, title: title}

      passport_rules = %{"editor.set" => true}
      rule_conn = simu_conn(:user, user, cms: passport_rules)

      result = rule_conn |> mutation_result(@set_editor_query, variables, "setEditor")

      assert result["id"] == to_string(user.id)
    end

    @unset_editor_query """
    mutation($communityId: ID!, $userId: ID!){
      unsetEditor(communityId: $communityId, userId: $userId) {
        id
      }
    }
    """
    test "auth user can unset editor AND passport from community", ~m(user community)a do
      title = "chief editor"

      {:ok, _} = CMS.set_editor(community, title, user)

      assert {:ok, _} =
               CommunityEditor |> ORM.find_by(user_id: user.id, community_id: community.id)

      assert {:ok, _} = Passport |> ORM.find_by(user_id: user.id)

      variables = %{userId: user.id, communityId: community.id}

      passport_rules = %{"editor.unset" => true}
      rule_conn = simu_conn(:user, user, cms: passport_rules)

      rule_conn |> mutation_result(@unset_editor_query, variables, "unsetEditor")

      assert {:error, _} =
               CommunityEditor |> ORM.find_by(user_id: user.id, community_id: community.id)

      assert {:error, _} = Passport |> ORM.find_by(user_id: user.id)
    end

    @update_editor_query """
    mutation($communityId: ID!, $userId: ID!, $title: String!){
      updateCmsEditor(communityId: $communityId, userId: $userId, title: $title) {
        id
      }
    }
    """
    test "auth user can update editor to community", ~m(user community)a do
      title = "chief editor"

      {:ok, _} =
        CMS.set_editor(
          community,
          title,
          user
        )

      title2 = "post editor"
      variables = %{userId: user.id, communityId: community.id, title: title2}

      passport_rules = %{"editor.update" => true}
      rule_conn = simu_conn(:user, user, cms: passport_rules)

      rule_conn |> mutation_result(@update_editor_query, variables, "updateCmsEditor")

      {:ok, update_community} = ORM.find(Community, community.id, preload: :editors)
      assert title2 == update_community.editors |> List.first() |> Map.get(:title)
    end

    test "unauth user add editor fails", ~m(user_conn guest_conn user community)a do
      title = "chief editor"

      variables = %{userId: user.id, communityId: community.id, title: title}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@set_editor_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@set_editor_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@set_editor_query, variables, ecode(:passport))
    end
  end

  describe "[mutation cms subscribes]" do
    @subscribe_query """
    mutation($communityId: ID!){
      subscribeCommunity(communityId: $communityId) {
        id
        subscribers {
          id
        }
      }
    }
    """
    test "login user can subscribe community", ~m(user community)a do
      login_conn = simu_conn(:user, user)

      variables = %{communityId: community.id}
      created = login_conn |> mutation_result(@subscribe_query, variables, "subscribeCommunity")

      assert created["id"] == to_string(community.id)
      assert created["subscribers"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
    end

    test "login user subscribe non-exsit community fails", ~m(user)a do
      login_conn = simu_conn(:user, user)
      variables = %{communityId: non_exsit_id()}

      assert login_conn |> mutation_get_error?(@subscribe_query, variables, ecode(:changeset))
    end

    test "guest user subscribe community fails", ~m(guest_conn community)a do
      variables = %{communityId: community.id}

      assert guest_conn |> mutation_get_error?(@subscribe_query, variables, ecode(:account_login))
    end

    test "subscribed community should inc it's own geo info", ~m(user community)a do
      login_conn = simu_conn(:user, user)

      variables = %{communityId: community.id}
      _created = login_conn |> mutation_result(@subscribe_query, variables, "subscribeCommunity")
      {:ok, community} = Community |> ORM.find(community.id)

      geo_info_data = community.geo_info |> Map.get("data")
      update_geo_city = geo_info_data |> Enum.find(fn g -> g["city"] == "成都" end)

      assert update_geo_city["value"] == 1
    end

    @unsubscribe_query """
    mutation($communityId: ID!){
      unsubscribeCommunity(communityId: $communityId) {
        id
        subscribers {
          id
        }
      }
    }
    """
    test "login user can unsubscribe community", ~m(user community)a do
      {:ok, cur_subscribers} =
        CMS.community_members(:subscribers, %Community{id: community.id}, %{page: 1, size: 10})

      assert false == cur_subscribers.entries |> Enum.any?(&(&1.id == user.id))

      {:ok, record} = CMS.subscribe_community(community, user)

      {:ok, cur_subscribers} =
        CMS.community_members(:subscribers, %Community{id: community.id}, %{page: 1, size: 10})

      assert true == cur_subscribers.entries |> Enum.any?(&(&1.id == user.id))

      login_conn = simu_conn(:user, user)

      variables = %{communityId: community.id}

      result =
        login_conn |> mutation_result(@unsubscribe_query, variables, "unsubscribeCommunity")

      {:ok, cur_subscribers} =
        CMS.community_members(:subscribers, %Community{id: community.id}, %{page: 1, size: 10})

      assert result["id"] == to_string(record.id)
      assert false == cur_subscribers.entries |> Enum.any?(&(&1.id == user.id))
    end

    test "other login user unsubscribe community fails", ~m(user_conn community)a do
      variables = %{communityId: community.id}

      assert user_conn |> mutation_get_error?(@unsubscribe_query, variables)
    end

    test "guest user unsubscribe community fails", ~m(guest_conn community)a do
      variables = %{communityId: community.id}

      assert guest_conn
             |> mutation_get_error?(@unsubscribe_query, variables, ecode(:account_login))
    end

    test "unsubscribed community should dec it's own geo info", ~m(user community)a do
      login_conn = simu_conn(:user, user)

      variables = %{communityId: community.id}
      _created = login_conn |> mutation_result(@subscribe_query, variables, "subscribeCommunity")
      {:ok, community} = Community |> ORM.find(community.id)

      geo_info_data = community.geo_info |> Map.get("data")
      update_geo_city = geo_info_data |> Enum.find(fn g -> g["city"] == "成都" end)

      assert update_geo_city["value"] == 1

      variables = %{communityId: community.id}
      login_conn |> mutation_result(@unsubscribe_query, variables, "unsubscribeCommunity")

      {:ok, community} = Community |> ORM.find(community.id)

      geo_info_data = community.geo_info |> Map.get("data")
      update_geo_city = geo_info_data |> Enum.find(fn g -> g["city"] == "成都" end)

      assert update_geo_city["value"] == 0
    end
  end

  describe "[passport]" do
    @query """
    mutation($userId: ID!, $rules: Json!) {
      stampCmsPassport(userId: $userId, rules: $rules) {
        id
      }
    }
    """
    @valid_passport_rules %{
      "javascript" => %{
        "post.article.delete" => true,
        "post.tag.edit" => true
      }
    }
    @valid_passport_rules2 %{
      "elixir" => %{
        "post.article.delete" => true,
        "post.tag.edit" => true
      }
    }
    test "can create/update passport with rules", ~m(user)a do
      variables = %{userId: user.id, rules: Jason.encode!(@valid_passport_rules)}
      rule_conn = simu_conn(:user, cms: %{"community.stamp_passport" => true})
      created = rule_conn |> mutation_result(@query, variables, "stampCmsPassport")

      {:ok, found} = ORM.find(Passport, created["id"])

      assert found.user_id == user.id
      assert Map.equal?(found.rules, @valid_passport_rules)

      # updated
      variables = %{userId: user.id, rules: Jason.encode!(@valid_passport_rules2)}
      rule_conn = simu_conn(:user, cms: %{"community.stamp_passport" => true})
      updated = rule_conn |> mutation_result(@query, variables, "stampCmsPassport")

      {:ok, found} = ORM.find(Passport, updated["id"])

      f1 = found.rules |> Map.get("javascript")
      t1 = @valid_passport_rules |> Map.get("javascript")

      f2 = found.rules |> Map.get("elixir")
      t2 = @valid_passport_rules2 |> Map.get("elixir")

      assert found.user_id == user.id
      assert Map.equal?(f1, t1)
      assert Map.equal?(f2, t2)
    end

    @false_passport_rules %{
      "python" => %{
        "post.article.delete" => false,
        "post.tag.edit" => true
      }
    }
    test "false rules will be delete from user's passport", ~m(user)a do
      variables = %{userId: user.id, rules: Jason.encode!(@false_passport_rules)}
      rule_conn = simu_conn(:user, cms: %{"community.stamp_passport" => true})
      created = rule_conn |> mutation_result(@query, variables, "stampCmsPassport")

      {:ok, found} = ORM.find(Passport, created["id"])
      rules = found.rules |> Map.get("python")

      assert Map.equal?(rules, %{"post.tag.edit" => true})
    end
  end
end
