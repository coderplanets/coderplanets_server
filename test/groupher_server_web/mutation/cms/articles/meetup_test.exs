defmodule GroupherServer.Test.Mutation.Articles.Meetup do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.Meetup

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})
    {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, meetup)

    {:ok, ~m(user_conn guest_conn owner_conn community user meetup)a}
  end

  describe "[mutation meetup curd]" do
    @create_meetup_query """
    mutation (
      $title: String!,
      $body: String,
      $communityId: ID!,
      $articleTags: [Id]
     ) {
      createMeetup(
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
    test "create meetup with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      meetup_attr = mock_attrs(:meetup)

      variables = meetup_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      created = user_conn |> mutation_result(@create_meetup_query, variables, "createMeetup")

      {:ok, found} = ORM.find(Meetup, created["id"])

      assert created["id"] == to_string(found.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)

      assert created["id"] == to_string(found.id)
    end

    test "create meetup with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :meetup, article_tag_attrs, user)

      meetup_attr = mock_attrs(:meetup)

      variables =
        meetup_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_meetup_query, variables, "createMeetup")
      {:ok, meetup} = ORM.find(Meetup, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, meetup.article_tags)
    end

    test "create meetup should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      meetup_attr = mock_attrs(:meetup, %{body: mock_xss_string()})
      variables = meetup_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      result = user_conn |> mutation_result(@create_meetup_query, variables, "createMeetup")

      {:ok, meetup} = ORM.find(Meetup, result["id"], preload: :document)
      body_html = meetup |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    test "create meetup should excape xss attracts 2" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      meetup_attr = mock_attrs(:meetup, %{body: mock_xss_string(:safe)})
      variables = meetup_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_meetup_query, variables, "createMeetup")
      {:ok, meetup} = ORM.find(Meetup, result["id"], preload: :document)
      body_html = meetup |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $articleTags: [Ids]){
      updateMeetup(id: $id, title: $title, body: $body, articleTags: $articleTags) {
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
    test "update a meetup without login user fails", ~m(guest_conn meetup)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: meetup.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "meetup can be update by owner", ~m(owner_conn meetup)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: meetup.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      result = owner_conn |> mutation_result(@query, variables, "updateMeetup")

      assert result["title"] == variables.title

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))
    end

    test "login user with auth passport update a meetup", ~m(meetup)a do
      meetup = meetup |> Repo.preload(:communities)

      meetup_communities_0 = meetup.communities |> List.first() |> Map.get(:title)
      passport_rules = %{meetup_communities_0 => %{"meetup.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: meetup.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated = rule_conn |> mutation_result(@query, variables, "updateMeetup")

      assert updated["id"] == to_string(meetup.id)
    end

    test "unauth user update meetup fails", ~m(user_conn guest_conn meetup)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: meetup.id,
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
      deleteMeetup(id: $id) {
        id
      }
    }
    """

    test "can delete a meetup by meetup's owner", ~m(owner_conn meetup)a do
      deleted = owner_conn |> mutation_result(@query, %{id: meetup.id}, "deleteMeetup")

      assert deleted["id"] == to_string(meetup.id)
      assert {:error, _} = ORM.find(Meetup, deleted["id"])
    end

    test "can delete a meetup by auth user", ~m(meetup)a do
      meetup = meetup |> Repo.preload(:communities)
      belongs_community_title = meetup.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"meetup.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: meetup.id}, "deleteMeetup")

      assert deleted["id"] == to_string(meetup.id)
      assert {:error, _} = ORM.find(Meetup, deleted["id"])
    end
  end
end
