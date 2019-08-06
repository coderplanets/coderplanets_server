defmodule GroupherServer.Test.Mutation.VideoFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, video} = CMS.create_content(community, :video, mock_attrs(:video), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community video)a}
  end

  describe "[mutation video flag curd]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      trashVideo(id: $id, communityId: $communityId) {
        id
        trash
      }
    }
    """
    test "auth user can trash video", ~m(community video)a do
      variables = %{id: video.id, communityId: community.id}

      passport_rules = %{community.raw => %{"video.trash" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "trashVideo")

      assert updated["id"] == to_string(video.id)
      assert updated["trash"] == true
    end

    test "unauth user trash video fails", ~m(user_conn guest_conn video community)a do
      variables = %{id: video.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoTrashVideo(id: $id, communityId: $communityId) {
        id
        trash
      }
    }
    """
    test "auth user can undo trash video", ~m(community video)a do
      variables = %{id: video.id, communityId: community.id}

      {:ok, _} = CMS.set_community_flags(community, video, %{trash: true})

      passport_rules = %{community.raw => %{"video.undo_trash" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoTrashVideo")

      assert updated["id"] == to_string(video.id)
      assert updated["trash"] == false
    end

    test "unauth user undo trash video fails", ~m(user_conn guest_conn community video)a do
      variables = %{id: video.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinVideo(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can pin video", ~m(community video)a do
      variables = %{id: video.id, communityId: community.id}

      passport_rules = %{community.raw => %{"video.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinVideo")

      assert updated["id"] == to_string(video.id)
    end

    test "unauth user pin video fails", ~m(user_conn guest_conn community video)a do
      variables = %{id: video.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinVideo(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "auth user can undo pin video", ~m(community video)a do
      variables = %{id: video.id, communityId: community.id}

      passport_rules = %{community.raw => %{"video.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_content(video, community)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinVideo")

      assert updated["id"] == to_string(video.id)
    end

    test "unauth user undo pin video fails", ~m(user_conn guest_conn community video)a do
      variables = %{id: video.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
