defmodule GroupherServer.Test.Mutation.Articles.Works do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.Works

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    works_attrs = mock_attrs(:works, %{community_id: community.id})
    {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, works)

    {:ok, ~m(user_conn guest_conn owner_conn community user works)a}
  end

  describe "[mutation works curd]" do
    @create_works_query """
    mutation (
      $title: String!,
      $body: String,
      $digest: String!,
      $length: Int,
      $communityId: ID!,
      $articleTags: [Id]
     ) {
      createWorks(
        title: $title,
        body: $body,
        digest: $digest,
        length: $length,
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
    test "create works with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      works_attr = mock_attrs(:works)

      variables = works_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      created = user_conn |> mutation_result(@create_works_query, variables, "createWorks")

      {:ok, found} = ORM.find(Works, created["id"])

      assert created["id"] == to_string(found.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)

      assert created["id"] == to_string(found.id)
    end

    test "create works with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)

      works_attr = mock_attrs(:works)

      variables =
        works_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_works_query, variables, "createWorks")
      {:ok, works} = ORM.find(Works, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, works.article_tags)
    end

    test "create works should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      works_attr = mock_attrs(:works, %{body: mock_xss_string()})
      variables = works_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_works_query, variables, "createWorks")

      {:ok, works} = ORM.find(Works, result["id"], preload: :document)
      body_html = works |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    test "create works should excape xss attracts 2" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      works_attr = mock_attrs(:works, %{body: mock_xss_string(:safe)})
      variables = works_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_works_query, variables, "createWorks")
      {:ok, works} = ORM.find(Works, result["id"], preload: :document)
      body_html = works |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $articleTags: [Ids]){
      updateWorks(id: $id, title: $title, body: $body, articleTags: $articleTags) {
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
    test "update a works without login user fails", ~m(guest_conn works)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: works.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "works can be update by owner", ~m(owner_conn works)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: works.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      result = owner_conn |> mutation_result(@query, variables, "updateWorks")

      assert result["title"] == variables.title

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))
    end

    test "login user with auth passport update a works", ~m(works)a do
      works = works |> Repo.preload(:communities)

      works_communities_0 = works.communities |> List.first() |> Map.get(:title)
      passport_rules = %{works_communities_0 => %{"works.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: works.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated = rule_conn |> mutation_result(@query, variables, "updateWorks")

      assert updated["id"] == to_string(works.id)
    end

    test "unauth user update works fails", ~m(user_conn guest_conn works)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: works.id,
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
      deleteWorks(id: $id) {
        id
      }
    }
    """

    test "can delete a works by works's owner", ~m(owner_conn works)a do
      deleted = owner_conn |> mutation_result(@query, %{id: works.id}, "deleteWorks")

      assert deleted["id"] == to_string(works.id)
      assert {:error, _} = ORM.find(Works, deleted["id"])
    end

    test "can delete a works by auth user", ~m(works)a do
      works = works |> Repo.preload(:communities)
      belongs_community_title = works.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"works.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: works.id}, "deleteWorks")

      assert deleted["id"] == to_string(works.id)
      assert {:error, _} = ORM.find(Works, deleted["id"])
    end
  end
end
