defmodule GroupherServer.Test.Mutation.PostFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, post} = CMS.create_content(community, :post, mock_attrs(:post), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community post)a}
  end

  describe "[mutation post flag curd]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      trashPost(id: $id, communityId: $communityId) {
        id
        trash
      }
    }
    """
    test "auth user can trash post", ~m(community post)a do
      variables = %{id: post.id, communityId: community.id}

      passport_rules = %{community.raw => %{"post.trash" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "trashPost")

      assert updated["id"] == to_string(post.id)
      assert updated["trash"] == true
    end

    test "unauth user trash post fails", ~m(user_conn guest_conn post community)a do
      variables = %{id: post.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoTrashPost(id: $id, communityId: $communityId) {
        id
        trash
      }
    }
    """
    test "auth user can undo trash post", ~m(community post)a do
      variables = %{id: post.id, communityId: community.id}

      {:ok, _} = CMS.set_community_flags(community, post, %{trash: true})

      passport_rules = %{community.raw => %{"post.undo_trash" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoTrashPost")

      assert updated["id"] == to_string(post.id)
      assert updated["trash"] == false
    end

    test "unauth user undo trash post fails", ~m(user_conn guest_conn community post)a do
      variables = %{id: post.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinPost(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can pin post", ~m(community post)a do
      variables = %{id: post.id, communityId: community.id}

      passport_rules = %{community.raw => %{"post.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinPost")

      assert updated["id"] == to_string(post.id)
    end

    test "unauth user pin post fails", ~m(user_conn guest_conn community post)a do
      variables = %{id: post.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinPost(id: $id, communityId: $communityId) {
        id
        isPinned
      }
    }
    """
    @tag :wip2
    test "auth user can undo pin post", ~m(community post)a do
      variables = %{id: post.id, communityId: community.id}

      passport_rules = %{community.raw => %{"post.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:post, post.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinPost")

      assert updated["id"] == to_string(post.id)
    end

    test "unauth user undo pin post fails", ~m(user_conn guest_conn community post)a do
      variables = %{id: post.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
