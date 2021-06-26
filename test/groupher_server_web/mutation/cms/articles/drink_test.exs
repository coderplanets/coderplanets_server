defmodule GroupherServer.Test.Mutation.Articles.Drink do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.Drink

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    drink_attrs = mock_attrs(:drink, %{community_id: community.id})
    {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, drink)

    {:ok, ~m(user_conn guest_conn owner_conn community user drink)a}
  end

  describe "[mutation drink curd]" do
    @create_drink_query """
    mutation (
      $title: String!,
      $body: String,
      $communityId: ID!,
      $articleTags: [Id]
     ) {
      createDrink(
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
    test "create drink with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      drink_attr = mock_attrs(:drink)

      variables = drink_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      created = user_conn |> mutation_result(@create_drink_query, variables, "createDrink")

      {:ok, found} = ORM.find(Drink, created["id"])

      assert created["id"] == to_string(found.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)

      assert created["id"] == to_string(found.id)
    end

    test "create drink with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :drink, article_tag_attrs, user)

      drink_attr = mock_attrs(:drink)

      variables =
        drink_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_drink_query, variables, "createDrink")

      {:ok, drink} = ORM.find(Drink, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, drink.article_tags)
    end

    test "create drink should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      drink_attr = mock_attrs(:drink, %{body: mock_xss_string()})
      variables = drink_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_drink_query, variables, "createDrink")

      {:ok, drink} = ORM.find(Drink, result["id"], preload: :document)
      body_html = drink |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    test "create drink should excape xss attracts 2" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      drink_attr = mock_attrs(:drink, %{body: mock_xss_string(:safe)})
      variables = drink_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_drink_query, variables, "createDrink")
      {:ok, drink} = ORM.find(Drink, result["id"], preload: :document)
      body_html = drink |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $articleTags: [Ids]){
      updateDrink(id: $id, title: $title, body: $body, articleTags: $articleTags) {
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
    test "update a drink without login user fails", ~m(guest_conn drink)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: drink.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "drink can be update by owner", ~m(owner_conn drink)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: drink.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      result = owner_conn |> mutation_result(@query, variables, "updateDrink")

      assert result["title"] == variables.title

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))
    end

    test "login user with auth passport update a drink", ~m(drink)a do
      drink = drink |> Repo.preload(:communities)

      drink_communities_0 = drink.communities |> List.first() |> Map.get(:title)
      passport_rules = %{drink_communities_0 => %{"drink.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: drink.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated = rule_conn |> mutation_result(@query, variables, "updateDrink")

      assert updated["id"] == to_string(drink.id)
    end

    test "unauth user update drink fails", ~m(user_conn guest_conn drink)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: drink.id,
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
      deleteDrink(id: $id) {
        id
      }
    }
    """

    test "can delete a drink by drink's owner", ~m(owner_conn drink)a do
      deleted = owner_conn |> mutation_result(@query, %{id: drink.id}, "deleteDrink")

      assert deleted["id"] == to_string(drink.id)
      assert {:error, _} = ORM.find(Drink, deleted["id"])
    end

    test "can delete a drink by auth user", ~m(drink)a do
      drink = drink |> Repo.preload(:communities)
      belongs_community_title = drink.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"drink.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: drink.id}, "deleteDrink")

      assert deleted["id"] == to_string(drink.id)
      assert {:error, _} = ORM.find(Drink, deleted["id"])
    end
  end
end
