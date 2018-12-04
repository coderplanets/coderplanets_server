defmodule MastaniServer.Test.Query.Account.Customization do
  use MastaniServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  @default_customization get_config(:customization, :all) |> Enum.into(%{})

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account customization]" do
    @query """
    query {
      user {
        id
        nickname
        customization {
          theme
          communityChart
          brainwashFree
          bannerLayout
          contentsLayout
          contentDivider
          markViewed
          displayDensity
        }
      }
    }
    """
    test "user can have default customization configs", ~m(user_conn user)a do
      results = user_conn |> query_result(@query, %{}, "user")

      assert results["id"] == to_string(user.id)
      assert results["customization"]["theme"] == @default_customization |> Map.get(:theme)

      assert results["customization"]["bannerLayout"] ==
               @default_customization |> Map.get(:banner_layout)

      assert results["customization"]["contentsLayout"] ==
               @default_customization |> Map.get(:contents_layout)
    end
  end
end
