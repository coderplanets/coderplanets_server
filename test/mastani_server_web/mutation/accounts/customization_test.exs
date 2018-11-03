defmodule MastaniServer.Test.Mutation.Account.Customization do
  use MastaniServer.TestTools

  # alias MastaniServer.{Accounts}
  # alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user, user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account customization mutation]" do
    @query """
    mutation($userId: ID, $customization: CustomizationInput!) {
      setCustomization( userId: $userId, customization: $customization) {
        id
        customization {
          bannerLayout
          contentDivider
          markViewed
          displayDensity
        }
      }
    }
    """
    @tag :wip2
    test "user can set customization", ~m(user_conn user)a do
      ownd_conn = simu_conn(:user, user)

      variables = %{
        customization: %{
          bannerLayout: "BRIEF",
          contentDivider: true,
          markViewed: false,
          displayDensity: "25"
        }
      }

      result = user_conn |> mutation_result(@query, variables, "setCustomization")

      assert result["customization"]["bannerLayout"] == "brief"
      assert result["customization"]["contentDivider"] == true
      assert result["customization"]["markViewed"] == false
      assert result["customization"]["displayDensity"] == "25"
    end

    @tag :wip2
    test "user set customization with invalid attr fails", ~m(user_conn user)a do
      ownd_conn = simu_conn(:user, user)

      variables1 = %{
        customization: %{
          bannerLayout: "OTHER"
        }
      }

      variables2 = %{
        customization: %{
          contentsLayout: "OTHER"
        }
      }

      assert user_conn |> mutation_get_error?(@query, variables1)
      assert user_conn |> mutation_get_error?(@query, variables2)
    end

    @tag :wip2
    test "unlogin user set customization fails", ~m(guest_conn)a do
      variables = %{
        customization: %{
          bannerLayout: "DIGEST"
        }
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
