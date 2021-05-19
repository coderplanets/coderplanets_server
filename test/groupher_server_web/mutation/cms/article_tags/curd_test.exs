defmodule GroupherServer.Test.Mutation.CMS.ArticleArticleTags.CURD do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.ArticleTag

  alias Helper.ORM

  setup do
    {:ok, community} = db_insert(:community)
    {:ok, thread} = db_insert(:thread)
    {:ok, user} = db_insert(:user)

    tag_attrs = mock_attrs(:tag)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn community thread user tag_attrs)a}
  end

  describe "[mutation cms tag]" do
    @create_tag_query """
    mutation($thread: Thread!, $title: String!, $color: RainbowColor!, $communityId: ID!) {
      createArticleTag(thread: $thread, title: $title, color: $color, communityId: $communityId) {
        id
        title
        color
        thread
        community {
          id
          logo
          title
        }
      }
    }
    """
    @tag :wip2
    test "create tag with valid attrs, has default POST thread and default posts",
         ~m(community)a do
      variables = %{
        title: "tag title",
        communityId: community.id,
        thread: "POST",
        color: "GREEN"
      }

      passport_rules = %{community.title => %{"post.article_tag.create" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      created = rule_conn |> mutation_result(@create_tag_query, variables, "createArticleTag")

      belong_community = created["community"]

      {:ok, found} = ArticleTag |> ORM.find(created["id"])

      assert created["id"] == to_string(found.id)
      assert found.thread == "POST"
      assert belong_community["id"] == to_string(community.id)
    end

    @tag :wip2
    test "unauth user create tag fails", ~m(community user_conn guest_conn)a do
      variables = %{
        title: "tag title",
        communityId: community.id,
        thread: "POST",
        color: "GREEN"
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@create_tag_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@create_tag_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@create_tag_query, variables, ecode(:passport))
    end

    @update_tag_query """
    mutation($id: ID!, $color: RainbowColor, $title: String, $communityId: ID!) {
      updateArticleTag(id: $id, color: $color, title: $title, communityId: $communityId) {
        id
        title
        color
      }
    }
    """
    @tag :wip2
    test "auth user can update a tag", ~m(tag_attrs community user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, tag_attrs, user)

      variables = %{
        id: article_tag.id,
        color: "YELLOW",
        title: "new title",
        communityId: community.id
      }

      passport_rules = %{community.title => %{"post.article_tag.update" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@update_tag_query, variables, "updateArticleTag")

      assert updated["color"] == "YELLOW"
      assert updated["title"] == "new title"
    end

    @delete_tag_query """
    mutation($id: ID!, $communityId: ID!){
      deleteArticleTag(id: $id, communityId: $communityId) {
        id
      }
    }
    """
    @tag :wip2
    test "auth user can delete tag", ~m(tag_attrs community user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, tag_attrs, user)

      variables = %{id: article_tag.id, communityId: community.id}

      rule_conn =
        simu_conn(:user,
          cms: %{community.title => %{"post.article_tag.delete" => true}}
        )

      deleted = rule_conn |> mutation_result(@delete_tag_query, variables, "deleteArticleTag")

      assert deleted["id"] == to_string(article_tag.id)
    end

    @tag :wip2
    test "unauth user delete tag fails", ~m(tag_attrs community user_conn guest_conn user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :post, tag_attrs, user)

      variables = %{id: article_tag.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@delete_tag_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@delete_tag_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@delete_tag_query, variables, ecode(:passport))
    end
  end
end
