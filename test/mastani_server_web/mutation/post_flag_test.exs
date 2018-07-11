defmodule MastaniServer.Test.Mutation.PostFlagTest do
  use MastaniServer.TestTools

  # alias MastaniServer.CMS
  # alias Helper.ORM

  setup do
    {:ok, post} = db_insert(:post)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, post)

    {:ok, ~m(user_conn guest_conn owner_conn post)a}
  end

  describe "[mutation post flag curd]" do
    @query """
    mutation($id: ID!){
      pinPost(id: $id) {
        id
        pin
      }
    }
    """
    test "auth user can pin post", ~m(post)a do
      variables = %{id: post.id}

      passport_rules = %{"post.pin" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      created = rule_conn |> mutation_result(@query, variables, "pinPost")

      assert created["id"] == to_string(post.id)
      assert created["pin"] == true
    end

    test "unauth user pin post fails", ~m(post user_conn guest_conn)a do
      variables = %{id: post.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
