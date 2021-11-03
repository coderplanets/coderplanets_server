defmodule GroupherServer.Test.Mutation.Articles.Radar do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.Radar

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    radar_attrs = mock_attrs(:radar, %{community_id: community.id})
    {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, radar)

    {:ok, ~m(user_conn guest_conn owner_conn community user radar)a}
  end

  describe "[mutation radar curd]" do
    @create_radar_query """
    mutation (
      $title: String!,
      $body: String,
      $linkAddr: String!
      $communityId: ID!,
      $articleTags: [Id]
     ) {
      createRadar(
        title: $title,
        body: $body,
        linkAddr: $linkAddr,
        communityId: $communityId,
        articleTags: $articleTags
        ) {
          id
          title
          linkAddr
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
    test "create radar with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      radar_attr = mock_attrs(:radar)

      variables = radar_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      created = user_conn |> mutation_result(@create_radar_query, variables, "createRadar")

      {:ok, found} = ORM.find(Radar, created["id"])

      assert created["id"] == to_string(found.id)
      assert not is_nil(created["linkAddr"])
      assert created["originalCommunity"]["id"] == to_string(community.id)

      assert created["id"] == to_string(found.id)
    end

    test "create radar with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :radar, article_tag_attrs, user)

      radar_attr = mock_attrs(:radar)

      variables =
        radar_attr
        |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})
        |> camelize_map_key

      created = user_conn |> mutation_result(@create_radar_query, variables, "createRadar")

      {:ok, radar} = ORM.find(Radar, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, radar.article_tags)
    end

    test "create radar should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      radar_attr = mock_attrs(:radar, %{body: mock_xss_string()})
      variables = radar_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_radar_query, variables, "createRadar")

      {:ok, radar} = ORM.find(Radar, result["id"], preload: :document)
      body_html = radar |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    test "create radar should excape xss attracts 2" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      radar_attr = mock_attrs(:radar, %{body: mock_xss_string(:safe)})
      variables = radar_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_radar_query, variables, "createRadar")
      {:ok, radar} = ORM.find(Radar, result["id"], preload: :document)
      body_html = radar |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $articleTags: [Ids]){
      updateRadar(id: $id, title: $title, body: $body, articleTags: $articleTags) {
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
    test "update a radar without login user fails", ~m(guest_conn radar)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: radar.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "radar can be update by owner", ~m(owner_conn radar)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: radar.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      result = owner_conn |> mutation_result(@query, variables, "updateRadar")

      assert result["title"] == variables.title

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))
    end

    test "login user with auth passport update a radar", ~m(radar)a do
      radar = radar |> Repo.preload(:communities)

      radar_communities_0 = radar.communities |> List.first() |> Map.get(:title)
      passport_rules = %{radar_communities_0 => %{"radar.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: radar.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated = rule_conn |> mutation_result(@query, variables, "updateRadar")

      assert updated["id"] == to_string(radar.id)
    end

    test "unauth user update radar fails", ~m(user_conn guest_conn radar)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: radar.id,
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
      deleteRadar(id: $id) {
        id
      }
    }
    """

    test "can delete a radar by radar's owner", ~m(owner_conn radar)a do
      deleted = owner_conn |> mutation_result(@query, %{id: radar.id}, "deleteRadar")

      assert deleted["id"] == to_string(radar.id)
      assert {:error, _} = ORM.find(Radar, deleted["id"])
    end

    test "can delete a radar by auth user", ~m(radar)a do
      radar = radar |> Repo.preload(:communities)
      belongs_community_title = radar.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"radar.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: radar.id}, "deleteRadar")

      assert deleted["id"] == to_string(radar.id)
      assert {:error, _} = ORM.find(Radar, deleted["id"])
    end
  end
end
