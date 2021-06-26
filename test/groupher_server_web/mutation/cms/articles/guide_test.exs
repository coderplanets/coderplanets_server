defmodule GroupherServer.Test.Mutation.Articles.Guide do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.Guide

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guide_attrs = mock_attrs(:guide, %{community_id: community.id})
    {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, guide)

    {:ok, ~m(user_conn guest_conn owner_conn community user guide)a}
  end

  describe "[mutation guide curd]" do
    @create_guide_query """
    mutation (
      $title: String!,
      $body: String,
      $communityId: ID!,
      $articleTags: [Id]
     ) {
      createGuide(
        title: $title,
        body: $body,
        communityId: $communityId,
        articleTags: $articleTags
        ) {
          id
          title
          document {
            bodyHtml
          }
          originalCommunity {
            id
          }
          communities {
            id
            title
          }
      }
    }
    """
    test "create guide with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      guide_attr = mock_attrs(:guide)

      variables = guide_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      created = user_conn |> mutation_result(@create_guide_query, variables, "createGuide")

      {:ok, found} = ORM.find(Guide, created["id"])

      assert created["id"] == to_string(found.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)

      assert created["id"] == to_string(found.id)
    end

    test "create guide with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)

      guide_attr = mock_attrs(:guide)

      variables =
        guide_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_guide_query, variables, "createGuide")

      {:ok, guide} = ORM.find(Guide, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, guide.article_tags)
    end

    test "create guide should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      guide_attr = mock_attrs(:guide, %{body: mock_xss_string()})
      variables = guide_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_guide_query, variables, "createGuide")

      {:ok, guide} = ORM.find(Guide, result["id"], preload: :document)
      body_html = guide |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    test "create guide should excape xss attracts 2" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      guide_attr = mock_attrs(:guide, %{body: mock_xss_string(:safe)})
      variables = guide_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_guide_query, variables, "createGuide")
      {:ok, guide} = ORM.find(Guide, result["id"], preload: :document)
      body_html = guide |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $articleTags: [Ids]){
      updateGuide(id: $id, title: $title, body: $body, articleTags: $articleTags) {
        id
        title
        document {
          bodyHtml
        }
        articleTags {
          id
        }
      }
    }
    """
    test "update a guide without login user fails", ~m(guest_conn guide)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: guide.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "guide can be update by owner", ~m(owner_conn guide)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: guide.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      result = owner_conn |> mutation_result(@query, variables, "updateGuide")

      assert result["title"] == variables.title

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))
    end

    test "login user with auth passport update a guide", ~m(guide)a do
      guide = guide |> Repo.preload(:communities)

      guide_communities_0 = guide.communities |> List.first() |> Map.get(:title)
      passport_rules = %{guide_communities_0 => %{"guide.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: guide.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated = rule_conn |> mutation_result(@query, variables, "updateGuide")

      assert updated["id"] == to_string(guide.id)
    end

    test "unauth user update guide fails", ~m(user_conn guest_conn guide)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: guide.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      deleteGuide(id: $id) {
        id
      }
    }
    """

    test "can delete a guide by guide's owner", ~m(owner_conn guide)a do
      deleted = owner_conn |> mutation_result(@query, %{id: guide.id}, "deleteGuide")

      assert deleted["id"] == to_string(guide.id)
      assert {:error, _} = ORM.find(Guide, deleted["id"])
    end

    test "can delete a guide by auth user", ~m(guide)a do
      guide = guide |> Repo.preload(:communities)
      belongs_community_title = guide.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"guide.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: guide.id}, "deleteGuide")

      assert deleted["id"] == to_string(guide.id)
      assert {:error, _} = ORM.find(Guide, deleted["id"])
    end
  end
end
