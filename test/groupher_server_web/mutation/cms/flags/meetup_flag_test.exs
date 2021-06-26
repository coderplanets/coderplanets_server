defmodule GroupherServer.Test.Mutation.Flags.MeetupFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Community

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, meetup} = CMS.create_article(community, :meetup, mock_attrs(:meetup), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community user meetup)a}
  end

  describe "[mutation meetup flag curd]" do
    @query """
    mutation($id: ID!){
      markDeleteMeetup(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can markDelete meetup", ~m(meetup)a do
      variables = %{id: meetup.id}

      passport_rules = %{"meetup.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeleteMeetup")

      assert updated["id"] == to_string(meetup.id)
      assert updated["markDelete"] == true
    end

    test "mark delete meetup should update meetup's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, meetup} = CMS.create_article(community, :meetup, mock_attrs(:meetup), user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.meetups_count == 1

      variables = %{id: meetup.id}
      passport_rules = %{"meetup.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@query, variables, "markDeleteMeetup")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.meetups_count == 0
    end

    test "unauth user markDelete meetup fails", ~m(user_conn guest_conn meetup)a do
      variables = %{id: meetup.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeleteMeetup(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can undo markDelete meetup", ~m(meetup)a do
      variables = %{id: meetup.id}

      {:ok, _} = CMS.mark_delete_article(:meetup, meetup.id)

      passport_rules = %{"meetup.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeleteMeetup")

      assert updated["id"] == to_string(meetup.id)
      assert updated["markDelete"] == false
    end

    test "undo mark delete meetup should update meetup's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, meetup} = CMS.create_article(community, :meetup, mock_attrs(:meetup), user)

      {:ok, _} = CMS.mark_delete_article(:meetup, meetup.id)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.meetups_count == 0

      variables = %{id: meetup.id}
      passport_rules = %{"meetup.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)
      rule_conn |> mutation_result(@query, variables, "undoMarkDeleteMeetup")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.meetups_count == 1
    end

    test "unauth user undo markDelete meetup fails", ~m(user_conn guest_conn meetup)a do
      variables = %{id: meetup.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinMeetup(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "auth user can pin meetup", ~m(community meetup)a do
      variables = %{id: meetup.id, communityId: community.id}

      passport_rules = %{community.raw => %{"meetup.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinMeetup")

      assert updated["id"] == to_string(meetup.id)
    end

    test "unauth user pin meetup fails", ~m(user_conn guest_conn community meetup)a do
      variables = %{id: meetup.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinMeetup(id: $id, communityId: $communityId) {
        id
        isPinned
      }
    }
    """

    test "auth user can undo pin meetup", ~m(community meetup)a do
      variables = %{id: meetup.id, communityId: community.id}

      passport_rules = %{community.raw => %{"meetup.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:meetup, meetup.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinMeetup")

      assert updated["id"] == to_string(meetup.id)
    end

    test "unauth user undo pin meetup fails", ~m(user_conn guest_conn community meetup)a do
      variables = %{id: meetup.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
