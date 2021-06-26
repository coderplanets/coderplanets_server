defmodule GroupherServer.Test.Mutation.AbuseReports.DrinkReport do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    drink_attrs = mock_attrs(:drink, %{community_id: community.id})

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community drink_attrs)a}
  end

  describe "[drink report/undo_report]" do
    @report_query """
    mutation($id: ID!, $reason: String!, $attr: String) {
      reportDrink(id: $id, reason: $reason, attr: $attr) {
        id
        title
      }
    }
    """

    test "login user can report a drink", ~m(community drink_attrs user user_conn)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

      variables = %{id: drink.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportDrink")

      assert article["id"] == to_string(drink.id)
    end

    @undo_report_query """
    mutation($id: ID!) {
      undoReportDrink(id: $id) {
        id
        title
      }
    }
    """

    test "login user can undo report a drink", ~m(community drink_attrs user user_conn)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

      variables = %{id: drink.id, reason: "reason"}
      article = user_conn |> mutation_result(@report_query, variables, "reportDrink")

      assert article["id"] == to_string(drink.id)

      variables = %{id: drink.id}

      article = user_conn |> mutation_result(@undo_report_query, variables, "undoReportDrink")

      assert article["id"] == to_string(drink.id)
    end
  end
end
