defmodule GroupherServer.Test.Mutation.Flags.GuideFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Community

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community user guide)a}
  end

  describe "[mutation guide flag curd]" do
    @query """
    mutation($id: ID!){
      markDeleteGuide(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can markDelete guide", ~m(guide)a do
      variables = %{id: guide.id}

      passport_rules = %{"guide.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeleteGuide")

      assert updated["id"] == to_string(guide.id)
      assert updated["markDelete"] == true
    end

    test "mark delete guide should update guide's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.guides_count == 1

      variables = %{id: guide.id}
      passport_rules = %{"guide.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@query, variables, "markDeleteGuide")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.guides_count == 0
    end

    test "unauth user markDelete guide fails", ~m(user_conn guest_conn guide)a do
      variables = %{id: guide.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeleteGuide(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can undo markDelete guide", ~m(guide)a do
      variables = %{id: guide.id}

      {:ok, _} = CMS.mark_delete_article(:guide, guide.id)

      passport_rules = %{"guide.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeleteGuide")

      assert updated["id"] == to_string(guide.id)
      assert updated["markDelete"] == false
    end

    test "undo mark delete guide should update guide's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)

      {:ok, _} = CMS.mark_delete_article(:guide, guide.id)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.guides_count == 0

      variables = %{id: guide.id}
      passport_rules = %{"guide.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)
      rule_conn |> mutation_result(@query, variables, "undoMarkDeleteGuide")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.guides_count == 1
    end

    test "unauth user undo markDelete guide fails", ~m(user_conn guest_conn guide)a do
      variables = %{id: guide.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinGuide(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "auth user can pin guide", ~m(community guide)a do
      variables = %{id: guide.id, communityId: community.id}

      passport_rules = %{community.raw => %{"guide.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinGuide")

      assert updated["id"] == to_string(guide.id)
    end

    test "unauth user pin guide fails", ~m(user_conn guest_conn community guide)a do
      variables = %{id: guide.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinGuide(id: $id, communityId: $communityId) {
        id
        isPinned
      }
    }
    """

    test "auth user can undo pin guide", ~m(community guide)a do
      variables = %{id: guide.id, communityId: community.id}

      passport_rules = %{community.raw => %{"guide.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:guide, guide.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinGuide")

      assert updated["id"] == to_string(guide.id)
    end

    test "unauth user undo pin guide fails", ~m(user_conn guest_conn community guide)a do
      variables = %{id: guide.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
