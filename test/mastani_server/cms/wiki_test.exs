defmodule MastaniServer.Test.Wiki do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.CMS

  alias CMS.{CommunityWiki}

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    wiki_attrs = mock_attrs(:wiki, %{community_id: community.id})

    {:ok, ~m(user community wiki_attrs)a}
  end

  describe "[cms wiki sync]" do
    @tag :wip
    test "can create create/sync a wiki to a community", ~m(community wiki_attrs)a do
      {:ok, wiki} = CMS.sync_github_content(community, :wiki, wiki_attrs)

      assert wiki.community_id == community.id
      assert wiki.last_sync == wiki_attrs.last_sync
    end

    @tag :wip
    test "can update a exsit wiki", ~m(community wiki_attrs)a do
      {:ok, wiki} = CMS.sync_github_content(community, :wiki, wiki_attrs)

      new_wiki_attrs = mock_attrs(:wiki, %{community_id: community.id, readme: "new readme"})
      {:ok, _} = CMS.sync_github_content(community, :wiki, new_wiki_attrs)
      {:ok, new_wiki} = CommunityWiki |> ORM.find(wiki.id)

      assert new_wiki.readme == "new readme"
    end

    @tag :wip
    test "can add contributor to wiki", ~m(community wiki_attrs)a do
      {:ok, wiki} = CMS.sync_github_content(community, :wiki, wiki_attrs)
      cur_contributors = wiki.contributors

      contributor_attrs = mock_attrs(:github_contributor)
      {:ok, wiki} = CMS.add_contributor(wiki, contributor_attrs)
      update_contributors = wiki.contributors

      assert length(update_contributors) == 1 + length(cur_contributors)
    end

    @tag :wip
    test "add some contributor fails", ~m(community wiki_attrs)a do
      {:ok, wiki} = CMS.sync_github_content(community, :wiki, wiki_attrs)
      cur_contributors = wiki.contributors

      contributor_attrs = mock_attrs(:github_contributor)
      {:ok, wiki} = CMS.add_contributor(wiki, contributor_attrs)
      update_contributors = wiki.contributors

      assert length(update_contributors) == 1 + length(cur_contributors)

      # add some again
      {:error, error} = CMS.add_contributor(wiki, contributor_attrs)
      assert error |> Keyword.get(:code) == ecode(:already_exsit)
    end
  end
end
