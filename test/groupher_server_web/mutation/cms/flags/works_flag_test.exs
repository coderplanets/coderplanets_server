defmodule GroupherServer.Test.Mutation.Flags.WorksFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Community

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, works} = CMS.create_article(community, :works, mock_attrs(:works), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community user works)a}
  end

  describe "[mutation works flag curd]" do
    @query """
    mutation($id: ID!){
      markDeleteWorks(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can markDelete works", ~m(works)a do
      variables = %{id: works.id}

      passport_rules = %{"works.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeleteWorks")

      assert updated["id"] == to_string(works.id)
      assert updated["markDelete"] == true
    end

    test "mark delete works should update works's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, works} = CMS.create_article(community, :works, mock_attrs(:works), user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.works_count == 1

      variables = %{id: works.id}
      passport_rules = %{"works.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@query, variables, "markDeleteWorks")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.works_count == 0
    end

    test "unauth user markDelete works fails", ~m(user_conn guest_conn works)a do
      variables = %{id: works.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeleteWorks(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can undo markDelete works", ~m(works)a do
      variables = %{id: works.id}

      {:ok, _} = CMS.mark_delete_article(:works, works.id)

      passport_rules = %{"works.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeleteWorks")

      assert updated["id"] == to_string(works.id)
      assert updated["markDelete"] == false
    end

    test "undo mark delete works should update works's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, works} = CMS.create_article(community, :works, mock_attrs(:works), user)

      {:ok, _} = CMS.mark_delete_article(:works, works.id)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.works_count == 0

      variables = %{id: works.id}
      passport_rules = %{"works.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)
      rule_conn |> mutation_result(@query, variables, "undoMarkDeleteWorks")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.works_count == 1
    end

    test "unauth user undo markDelete works fails", ~m(user_conn guest_conn works)a do
      variables = %{id: works.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinWorks(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "auth user can pin works", ~m(community works)a do
      variables = %{id: works.id, communityId: community.id}

      passport_rules = %{community.raw => %{"works.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinWorks")

      assert updated["id"] == to_string(works.id)
    end

    test "unauth user pin works fails", ~m(user_conn guest_conn community works)a do
      variables = %{id: works.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinWorks(id: $id, communityId: $communityId) {
        id
        isPinned
      }
    }
    """

    test "auth user can undo pin works", ~m(community works)a do
      variables = %{id: works.id, communityId: community.id}

      passport_rules = %{community.raw => %{"works.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:works, works.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinWorks")

      assert updated["id"] == to_string(works.id)
    end

    test "unauth user undo pin works fails", ~m(user_conn guest_conn community works)a do
      variables = %{id: works.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
