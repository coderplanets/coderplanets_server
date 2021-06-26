defmodule GroupherServer.Test.Mutation.Upvotes.DrinkUpvote do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, drink} = db_insert(:drink)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn drink user)a}
  end

  describe "[drink upvote]" do
    @query """
    mutation($id: ID!) {
      upvoteDrink(id: $id) {
        id
      }
    }
    """

    test "login user can upvote a drink", ~m(user_conn drink)a do
      variables = %{id: drink.id}
      created = user_conn |> mutation_result(@query, variables, "upvoteDrink")

      assert created["id"] == to_string(drink.id)
    end

    test "unauth user upvote a drink fails", ~m(guest_conn drink)a do
      variables = %{id: drink.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      undoUpvoteDrink(id: $id) {
        id
      }
    }
    """

    test "login user can undo upvote to a drink", ~m(user_conn drink user)a do
      {:ok, _} = CMS.upvote_article(:drink, drink.id, user)

      variables = %{id: drink.id}
      updated = user_conn |> mutation_result(@query, variables, "undoUpvoteDrink")

      assert updated["id"] == to_string(drink.id)
    end

    test "unauth user undo upvote a drink fails", ~m(guest_conn drink)a do
      variables = %{id: drink.id}

      assert guest_conn
             |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
