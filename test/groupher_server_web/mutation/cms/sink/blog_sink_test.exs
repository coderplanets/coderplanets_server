defmodule GroupherServer.Test.Mutation.Sink.BlogSink do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Blog

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, blog} = CMS.create_article(community, :blog, mock_attrs(:blog), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn community blog user)a}
  end

  describe "[blog sink]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      sinkBlog(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can sink a blog", ~m(community blog)a do
      variables = %{id: blog.id, communityId: community.id}
      passport_rules = %{community.raw => %{"blog.sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "sinkBlog")
      assert result["id"] == to_string(blog.id)

      {:ok, blog} = ORM.find(Blog, blog.id)
      assert blog.meta.is_sinked
      assert blog.active_at == blog.inserted_at
    end

    test "unauth user sink a blog fails", ~m(guest_conn community blog)a do
      variables = %{id: blog.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoSinkBlog(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can undo sink to a blog", ~m(community blog)a do
      variables = %{id: blog.id, communityId: community.id}

      passport_rules = %{community.raw => %{"blog.undo_sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, _} = CMS.sink_article(:blog, blog.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoSinkBlog")
      assert updated["id"] == to_string(blog.id)

      {:ok, blog} = ORM.find(Blog, blog.id)
      assert not blog.meta.is_sinked
    end

    test "unauth user undo sink a blog fails", ~m(guest_conn community blog)a do
      variables = %{id: blog.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
