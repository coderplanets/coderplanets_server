defmodule GroupherServer.Test.Mutation.CMS.Wiki do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.CommunityWiki

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    wiki_attrs = mock_attrs(:wiki, %{community_id: community.id})
    {:ok, wiki} = CMS.sync_github_content(community, :wiki, wiki_attrs)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn community user wiki)a}
  end

  @sync_wiki_query """
  mutation($communityId: ID!, $readme: String!, $lastSync: DateTime!){
    syncWiki(communityId: $communityId, readme: $readme, lastSync: $lastSync) {
      id
      readme
    }
  }
  """
  test "login user can sync wiki", ~m(community)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    wiki_attrs = mock_attrs(:wiki) |> camelize_map_key

    variables = wiki_attrs |> Map.merge(%{communityId: community.id})
    created = user_conn |> mutation_result(@sync_wiki_query, variables, "syncWiki")

    {:ok, wiki} = ORM.find(CommunityWiki, created["id"])

    assert created["id"] == to_string(wiki.id)
    assert created["readme"] == to_string(wiki.readme)
  end

  @add_wiki_contribotor_query """
  mutation($id: ID!, $contributor: GithubContributorInput!){
    addWikiContributor(id: $id, contributor: $contributor) {
      id
      readme
      contributors {
        nickname
      }
    }
  }
  """
  test "login user can add contributor to an exsit wiki", ~m(wiki)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    contributor_attrs = mock_attrs(:github_contributor)
    variables = %{id: wiki.id, contributor: contributor_attrs}

    created =
      user_conn |> mutation_result(@add_wiki_contribotor_query, variables, "addWikiContributor")

    assert created["contributors"] |> length == 4
  end

  test "add some contributor fails", ~m(wiki)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    contributor_attrs = mock_attrs(:github_contributor)
    variables = %{id: wiki.id, contributor: contributor_attrs}

    user_conn |> mutation_result(@add_wiki_contribotor_query, variables, "addWikiContributor")

    assert user_conn
           |> mutation_get_error?(@add_wiki_contribotor_query, variables, ecode(:already_exsit))
  end
end
