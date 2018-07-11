defmodule MastaniServer.Test.Mutation.PostFlagTest do
  use MastaniServer.TestTools

  alias MastaniServer.CMS
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
      trashPost(id: $id) {
        id
        trash
      }
    }
    """
    test "auth user can trash post", ~m(post)a do
      variables = %{id: post.id}

      passport_rules = %{"post.trash" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "trashPost")

      assert updated["id"] == to_string(post.id)
      assert updated["trash"] == true
    end

    test "unauth user trash post fails", ~m(post user_conn guest_conn)a do
      variables = %{id: post.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoTrashPost(id: $id) {
        id
        trash
      }
    }
    """
    test "auth user can undo trash post", ~m(post)a do
      variables = %{id: post.id}

      {:ok, user} = db_insert(:user)
      {:ok, _} = CMS.set_flag(CMS.Post, post.id, %{trash: true}, user)

      passport_rules = %{"post.undo_trash" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoTrashPost")

      assert updated["id"] == to_string(post.id)
      assert updated["trash"] == false
    end

    test "unauth user undo trash post fails", ~m(post user_conn guest_conn)a do
      variables = %{id: post.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

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

      updated = rule_conn |> mutation_result(@query, variables, "pinPost")

      assert updated["id"] == to_string(post.id)
      assert updated["pin"] == true
    end

    test "unauth user pin post fails", ~m(post user_conn guest_conn)a do
      variables = %{id: post.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoPinPost(id: $id) {
        id
        pin
      }
    }
    """
    test "auth user can undo pin post", ~m(post)a do
      variables = %{id: post.id}

      {:ok, user} = db_insert(:user)
      {:ok, _} = CMS.set_flag(CMS.Post, post.id, %{pin: true}, user)

      passport_rules = %{"post.undo_pin" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoPinPost")

      assert updated["id"] == to_string(post.id)
      assert updated["pin"] == false
    end

    test "unauth user undo pin post fails", ~m(post user_conn guest_conn)a do
      variables = %{id: post.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
