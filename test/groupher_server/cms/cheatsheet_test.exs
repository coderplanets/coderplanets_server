defmodule GroupherServer.Test.CMS.Cheatsheet do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{CommunityCheatsheet}

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    cheatsheet_attrs = mock_attrs(:cheatsheet, %{community_id: community.id})

    {:ok, ~m(user community cheatsheet_attrs)a}
  end

  describe "[cms cheatsheet sync]" do
    test "can create create/sync a cheatsheet to a community", ~m(community cheatsheet_attrs)a do
      {:ok, cheatsheet} = CMS.sync_github_content(community, :cheatsheet, cheatsheet_attrs)

      assert cheatsheet.community_id == community.id
      assert cheatsheet.last_sync == cheatsheet_attrs.last_sync
    end

    test "can update a exsit cheatsheet", ~m(community cheatsheet_attrs)a do
      {:ok, cheatsheet} = CMS.sync_github_content(community, :cheatsheet, cheatsheet_attrs)

      new_cheatsheet_attrs =
        mock_attrs(:cheatsheet, %{community_id: community.id, readme: "new readme"})

      {:ok, _} = CMS.sync_github_content(community, :cheatsheet, new_cheatsheet_attrs)
      {:ok, new_cheatsheet} = CommunityCheatsheet |> ORM.find(cheatsheet.id)

      assert new_cheatsheet.readme == "new readme"
    end

    test "can add contributor to cheatsheet", ~m(community cheatsheet_attrs)a do
      {:ok, cheatsheet} = CMS.sync_github_content(community, :cheatsheet, cheatsheet_attrs)
      cur_contributors = cheatsheet.contributors

      contributor_attrs = mock_attrs(:github_contributor)
      {:ok, cheatsheet} = CMS.add_contributor(cheatsheet, contributor_attrs)
      update_contributors = cheatsheet.contributors

      assert length(update_contributors) == 1 + length(cur_contributors)
    end

    test "add some contributor fails", ~m(community cheatsheet_attrs)a do
      {:ok, cheatsheet} = CMS.sync_github_content(community, :cheatsheet, cheatsheet_attrs)
      cur_contributors = cheatsheet.contributors

      contributor_attrs = mock_attrs(:github_contributor)
      {:ok, cheatsheet} = CMS.add_contributor(cheatsheet, contributor_attrs)
      update_contributors = cheatsheet.contributors

      assert length(update_contributors) == 1 + length(cur_contributors)

      # add some again
      {:error, reason} = CMS.add_contributor(cheatsheet, contributor_attrs)
      assert reason |> Keyword.get(:code) == ecode(:already_exsit)
    end
  end
end
