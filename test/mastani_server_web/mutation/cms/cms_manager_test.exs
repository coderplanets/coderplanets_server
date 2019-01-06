defmodule MastaniServer.Test.Mutation.CMS.Manager do
  use MastaniServer.TestTools

  alias MastaniServer.CMS
  # alias CMS.{Category, Community, CommunityEditor, Passport, Tag, Thread}
  alias Helper.ORM

  setup do
    {:ok, post} = db_insert(:post)
    # {:ok, category} = db_insert(:category)
    {:ok, community} = db_insert(:community)
    # {:ok, thread} = db_insert(:thread)
    {:ok, tag} = db_insert(:tag, %{community: community})
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn community post user tag)a}
  end

  describe "root mutation" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      trashPost(id: $id, communityId: $communityId) {
        id
        trash
      }
    }
    """
    test "root can trash a post", ~m(community user)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id})
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      variables = %{id: post.id, communityId: community.id}

      passport_rules = %{"root" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "trashPost")

      assert updated["id"] == to_string(post.id)
      assert updated["trash"] == true
    end

    @query """
    mutation($id: ID!){
      deletePost(id: $id) {
        id
      }
    }
    """
    test "root can delete a post", ~m(post)a do
      passport_rules = %{"root" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      deleted = rule_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
      assert {:error, _} = ORM.find(CMS.Post, deleted["id"])
    end

    test "root can delete a post with comment", ~m(post user)a do
      passport_rules = %{"root" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      body = "this is a test comment"
      {:ok, comment} = CMS.create_comment(:post, post.id, %{body: body}, user)
      {:ok, _} = ORM.find(CMS.PostComment, comment.id)

      deleted = rule_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
      assert {:error, _} = ORM.find(CMS.Post, deleted["id"])
      assert {:error, _error} = ORM.find(CMS.PostComment, comment.id)
    end
  end
end
