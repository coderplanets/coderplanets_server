defmodule GroupherServer.Test.Mutation.Flags.BlogFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Community

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community user blog)a}
  end

  describe "[mutation blog flag curd]" do
    @query """
    mutation($id: ID!){
      markDeleteBlog(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can markDelete blog", ~m(blog)a do
      variables = %{id: blog.id}

      passport_rules = %{"blog.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeleteBlog")

      assert updated["id"] == to_string(blog.id)
      assert updated["markDelete"] == true
    end

    test "mark delete blog should update blog's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.blogs_count == 1

      variables = %{id: blog.id}
      passport_rules = %{"blog.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@query, variables, "markDeleteBlog")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.blogs_count == 0
    end

    test "unauth user markDelete blog fails", ~m(user_conn guest_conn blog)a do
      variables = %{id: blog.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeleteBlog(id: $id) {
        id
        markDelete
      }
    }
    """
    test "auth user can undo markDelete blog", ~m(blog)a do
      variables = %{id: blog.id}

      {:ok, _} = CMS.mark_delete_article(:blog, blog.id)

      passport_rules = %{"blog.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeleteBlog")

      assert updated["id"] == to_string(blog.id)
      assert updated["markDelete"] == false
    end

    test "undo mark delete blog should update blog's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)

      {:ok, _} = CMS.mark_delete_article(:blog, blog.id)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.blogs_count == 0

      variables = %{id: blog.id}
      passport_rules = %{"blog.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)
      rule_conn |> mutation_result(@query, variables, "undoMarkDeleteBlog")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.blogs_count == 1
    end

    test "unauth user undo markDelete blog fails", ~m(user_conn guest_conn blog)a do
      variables = %{id: blog.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinBlog(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "auth user can pin blog", ~m(community blog)a do
      variables = %{id: blog.id, communityId: community.id}

      passport_rules = %{community.raw => %{"blog.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinBlog")

      assert updated["id"] == to_string(blog.id)
    end

    test "unauth user pin blog fails", ~m(user_conn guest_conn community blog)a do
      variables = %{id: blog.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinBlog(id: $id, communityId: $communityId) {
        id
        isPinned
      }
    }
    """

    test "auth user can undo pin blog", ~m(community blog)a do
      variables = %{id: blog.id, communityId: community.id}

      passport_rules = %{community.raw => %{"blog.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:blog, blog.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinBlog")

      assert updated["id"] == to_string(blog.id)
    end

    test "unauth user undo pin blog fails", ~m(user_conn guest_conn community blog)a do
      variables = %{id: blog.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
