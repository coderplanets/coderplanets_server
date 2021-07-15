defmodule GroupherServer.Test.Mutation.Sink.PostSink do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Post

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, post} = CMS.create_article(community, :post, mock_attrs(:post), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn community post user)a}
  end

  describe "[post sink]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      sinkPost(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    test "login user can sink a post", ~m(community post)a do
      variables = %{id: post.id, communityId: community.id}
      passport_rules = %{community.raw => %{"post.sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "sinkPost")
      assert result["id"] == to_string(post.id)

      {:ok, post} = ORM.find(Post, post.id)
      assert post.meta.is_sinked
      assert post.active_at == post.inserted_at
    end

    test "unauth user sink a post fails", ~m(guest_conn community post)a do
      variables = %{id: post.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoSinkPost(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can undo sink to a post", ~m(community post)a do
      variables = %{id: post.id, communityId: community.id}

      passport_rules = %{community.raw => %{"post.undo_sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, _} = CMS.sink_article(:post, post.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoSinkPost")
      assert updated["id"] == to_string(post.id)

      {:ok, post} = ORM.find(Post, post.id)
      assert not post.meta.is_sinked
    end

    test "unauth user undo sink a post fails", ~m(guest_conn community post)a do
      variables = %{id: post.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
