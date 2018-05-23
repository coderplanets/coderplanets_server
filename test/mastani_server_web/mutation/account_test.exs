defmodule MastaniServer.Test.Mutation.AccountTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.ConnSimulator
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  # alias MastaniServer.{Accounts}
  # alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account update]" do
    @update_query """
    mutation($profile: UserProfileInput!) {
      updateProfile(profile: $profile) {
        id
        nickname
      }
    }
    """
    test "user can update it's own profile", ~m(user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        profile: %{
          nickname: "new nickname"
        }
      }

      updated = ownd_conn |> mutation_result(@update_query, variables, "updateProfile")

      assert updated["nickname"] == "new nickname"
    end

    test "user's profile can not updated by guest", ~m(guest_conn)a do
      variables = %{
        profile: %{
          nickname: "new nickname"
        }
      }

      assert guest_conn |> mutation_get_error?(@update_query, variables)
    end
  end
end
