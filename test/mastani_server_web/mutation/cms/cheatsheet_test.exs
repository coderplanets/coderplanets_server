defmodule MastaniServer.Test.Mutation.CMS.Cheatsheet do
  use MastaniServer.TestTools

  alias MastaniServer.CMS
  alias MastaniServer.Statistics

  alias CMS.{Community}

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    cheatsheet_attrs = mock_attrs(:cheatsheet, %{community_id: community.id})
    {:ok, cheatsheet} = CMS.sync_github_content(community, :cheatsheet, cheatsheet_attrs)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn community user cheatsheet)a}
  end

  @sync_cheatsheet_query """
  mutation($communityId: ID!, $readme: String!, $lastSync: String!){
    syncCheatsheet(communityId: $communityId, readme: $readme, lastSync: $lastSync) {
      id
      readme
    }
  }
  """
  @tag :wip
  test "login user can sync cheatsheet", ~m(community)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    cheatsheet_attrs = mock_attrs(:cheatsheet)

    variables = cheatsheet_attrs |> Map.merge(%{communityId: community.id})
    created = user_conn |> mutation_result(@sync_cheatsheet_query, variables, "syncCheatsheet")

    {:ok, cheatsheet} = ORM.find(CMS.CommunityCheatsheet, created["id"])

    assert created["id"] == to_string(cheatsheet.id)
    assert created["readme"] == to_string(cheatsheet.readme)
  end

  @add_cheatsheet_contribotor_query """
  mutation($id: ID!, $contributor: GithubContributorInput!){
    addCheatsheetContributor(id: $id, contributor: $contributor) {
      id
      readme
      contributors {
        nickname
      }
    }
  }
  """
  test "login user can add contributor to an exsit cheatsheet", ~m(user cheatsheet)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    contributor_attrs = mock_attrs(:github_contributor)
    variables = %{id: cheatsheet.id, contributor: contributor_attrs}

    created =
      user_conn
      |> mutation_result(@add_cheatsheet_contribotor_query, variables, "addCheatsheetContributor")

    assert created["contributors"] |> length == 4
  end

  test "add some contributor fails", ~m(user cheatsheet)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    contributor_attrs = mock_attrs(:github_contributor)
    variables = %{id: cheatsheet.id, contributor: contributor_attrs}

    created =
      user_conn
      |> mutation_result(@add_cheatsheet_contribotor_query, variables, "addCheatshhetContributor")

    assert user_conn
           |> mutation_get_error?(
             @add_cheatsheet_contribotor_query,
             variables,
             ecode(:already_exsit)
           )
  end
end
