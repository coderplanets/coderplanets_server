defmodule GroupherServer.Test.Mutation.Sink.RepoSink do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Repo

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn community repo user)a}
  end

  describe "[repo sink]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      sinkRepo(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can sink a repo", ~m(community repo)a do
      variables = %{id: repo.id, communityId: community.id}
      passport_rules = %{community.raw => %{"repo.sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "sinkRepo")
      assert result["id"] == to_string(repo.id)

      {:ok, repo} = ORM.find(Repo, repo.id)
      assert repo.meta.is_sinked
      assert repo.active_at == repo.inserted_at
    end

    test "unauth user sink a repo fails", ~m(guest_conn community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoSinkRepo(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "login user can undo sink to a repo", ~m(community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      passport_rules = %{community.raw => %{"repo.undo_sink" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      {:ok, _} = CMS.sink_article(:repo, repo.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoSinkRepo")
      assert updated["id"] == to_string(repo.id)

      {:ok, repo} = ORM.find(Repo, repo.id)
      assert not repo.meta.is_sinked
    end

    test "unauth user undo sink a repo fails", ~m(guest_conn community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
