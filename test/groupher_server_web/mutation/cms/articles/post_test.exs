defmodule GroupherServer.Test.Mutation.Articles.Post do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.{Post, Author}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})
    {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, post)

    {:ok, ~m(user_conn guest_conn owner_conn user community post)a}
  end

  describe "[mutation post curd]" do
    @create_post_query """
    mutation(
      $title: String!
      $body: String!
      $communityId: ID!
      $articleTags: [Id]
      $linkAddr: String
    ) {
      createPost(
        title: $title
        body: $body
        communityId: $communityId
        articleTags: $articleTags
        linkAddr: $linkAddr
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
      }
    }
    """
    test "create post with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post) |> Map.merge(%{linkAddr: "https://helloworld"})

      # body = """
      # {"time":1639375020110,"blocks":[{"type":"list","data":{"mode":"unordered_list","items":[{"text":"CP 的图标是字母 C (Coder / China) 和 Planet 的意象结合，斜向的条饰灵感来自于 NASA Logo 上的 \"red chevron\"。","label":null,"labelType":null,"checked":false,"hideLabel":true,"prefixIndex":"","indent":0},{"text":"所有的 Upvote 的图标都是小火箭，点击它会有一个起飞的动画 — 虽然它目前看起来像爆炸。。","label":null,"labelType":null,"checked":false,"hideLabel":true,"prefixIndex":"","indent":0}]}}],"version":"2.19.38"}
      # """
      body = """
      {"time":1639375020110,"blocks":[{"type":"list","data":{"mode":"unordered_list","items":[{"text":"CP 的图标是字母 C (Coder / China) 和 Planet 的意象结合，斜向的条饰灵感来自于 NASA Logo 上的 red chevron。","label":null,"labelType":null,"checked":false,"hideLabel":true,"prefixIndex":"","indent":0},{"text":"所有的 Upvote 的图标都是小火箭，点击它会有一个起飞的动画 — 虽然它目前看起来像爆炸。。","label":null,"labelType":null,"checked":false,"hideLabel":true,"prefixIndex":"","indent":0}]}}],"version":"2.19.38"}
      """

      variables = post_attr |> Map.merge(%{communityId: community.id, body: body})
      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")

      {:ok, post} = ORM.find(Post, created["id"])

      assert created["id"] == to_string(post.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)
      assert created["linkAddr"] == "https://helloworld"

      assert {:ok, _} = ORM.find_by(Author, user_id: user.id)
    end

    test "create post with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)

      post_attr = mock_attrs(:post)

      variables =
        post_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(Post, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, post.article_tags)
    end

    test "create post should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      post_attr = mock_attrs(:post, %{body: mock_xss_string()})
      variables = post_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(Post, result["id"], preload: :document)
      body_html = post |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    test "create post should excape xss attracts 2" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      post_attr = mock_attrs(:post, %{body: mock_xss_string(:safe)})
      variables = post_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_post_query, variables, "createPost")
      {:ok, post} = ORM.find(Post, result["id"], preload: :document)
      body_html = post |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    # NOTE: this test is IMPORTANT, cause json_codec: Jason in router will cause
    # server crash when GraphQL parse error
    test "create post with missing non_null field should get 200 error" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)
      variables = post_attr |> Map.merge(%{communityId: community.id}) |> Map.delete(:title)

      assert user_conn |> mutation_get_error?(@create_post_query, variables)
    end

    @query """
    mutation($id: ID!){
      deletePost(id: $id) {
        id
      }
    }
    """

    test "delete a post by post's owner", ~m(owner_conn post)a do
      deleted = owner_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
      assert {:error, _} = ORM.find(Post, deleted["id"])
    end

    test "can delete a post by auth user", ~m(post)a do
      post = post |> Repo.preload(:communities)
      belongs_community_title = post.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"post.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
      assert {:error, _} = ORM.find(Post, deleted["id"])
    end

    test "delete a post without login user fails", ~m(guest_conn post)a do
      assert guest_conn |> mutation_get_error?(@query, %{id: post.id}, ecode(:account_login))
    end

    test "login user with auth passport delete a post", ~m(post)a do
      post = post |> Repo.preload(:communities)
      post_communities_0 = post.communities |> List.first() |> Map.get(:title)
      passport_rules = %{post_communities_0 => %{"post.delete" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: post.id})

      deleted = rule_conn |> mutation_result(@query, %{id: post.id}, "deletePost")

      assert deleted["id"] == to_string(post.id)
    end

    test "unauth user delete post fails", ~m(user_conn guest_conn post)a do
      variables = %{id: post.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $copyRight: String, $articleTags: [Id]){
      updatePost(id: $id, title: $title, body: $body, copyRight: $copyRight, articleTags: $articleTags) {
        id
        title
        document {
          bodyHtml
        }
        copyRight
        meta {
          isEdited
        }
        commentsParticipants {
          id
          nickname
        }
        articleTags {
          id
        }
      }
    }
    """

    test "update a post without login user fails", ~m(guest_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "post can be update by owner", ~m(owner_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        # body: mock_rich_text("updated body #{unique_num}"),,
        body: mock_rich_text("updated body #{unique_num}"),
        copyRight: "translate"
      }

      result = owner_conn |> mutation_result(@query, variables, "updatePost")
      assert result["title"] == variables.title

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))

      assert result["copyRight"] == variables.copyRight
    end

    test "update post with valid attrs should have is_edited meta info update",
         ~m(owner_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated_post = owner_conn |> mutation_result(@query, variables, "updatePost")

      assert true == updated_post["meta"]["isEdited"]
    end

    test "login user with auth passport update a post", ~m(post)a do
      post = post |> Repo.preload(:communities)
      belongs_community_title = post.communities |> List.first() |> Map.get(:title)

      passport_rules = %{belongs_community_title => %{"post.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: post.id})
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated_post = rule_conn |> mutation_result(@query, variables, "updatePost")

      assert updated_post["id"] == to_string(post.id)
    end

    test "unauth user update post fails", ~m(user_conn guest_conn post)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: post.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
