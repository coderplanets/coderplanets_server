defmodule GroupherServer.Test.Mutation.Articles.Blog do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.Blog

  @rss mock_rss_addr()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})
    {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, blog)

    {:ok, ~m(user_conn guest_conn owner_conn community user blog)a}
  end

  describe "[mutation blog curd]" do
    @create_blog_query """
    mutation (
      $title: String!,
      $rss: String!,
      $communityId: ID!,
      $articleTags: [Id]
     ) {
      createBlog(
        title: $title,
        rss: $rss,
        communityId: $communityId,
        articleTags: $articleTags
        ) {
          id
          title
          digest
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
    test "create blog with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      blog_attr = mock_attrs(:blog) |> Map.merge(%{rss: @rss})
      variables = blog_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key

      created = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")

      {:ok, found} = ORM.find(Blog, created["id"])

      assert created["id"] == to_string(found.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)
      assert created["id"] == to_string(found.id)
    end

    test "create blog with non-exsit title fails" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      blog_attr = mock_attrs(:blog) |> Map.merge(%{rss: @rss})

      variables =
        blog_attr
        |> Map.merge(%{communityId: community.id, title: "non-exsit"})
        |> camelize_map_key

      assert user_conn
             |> mutation_get_error?(@create_blog_query, variables, ecode(:invalid_blog_title))
    end

    test "create blog with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)

      blog_attr = mock_attrs(:blog)

      variables =
        blog_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")
      {:ok, blog} = ORM.find(Blog, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, blog.article_tags)
    end

    test "create blog should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      blog_attr = mock_attrs(:blog, %{body: mock_xss_string()})
      variables = blog_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")

      {:ok, blog} = ORM.find(Blog, result["id"], preload: :document)
      body_html = blog |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    # test "create blog should excape xss attracts" do
    #   {:ok, user} = db_insert(:user)
    #   user_conn = simu_conn(:user, user)

    #   {:ok, community} = db_insert(:community)

    #   blog_attr = mock_attrs(:blog, %{body: mock_xss_string(:safe)})
    #   variables = blog_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
    #   result = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")
    #   {:ok, blog} = ORM.find(Blog, result["id"], preload: :document)
    #   body_html = blog |> get_in([:document, :body_html])

    #   assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    # end

    @query """
    mutation($id: ID!){
      deleteBlog(id: $id) {
        id
      }
    }
    """

    test "can delete a blog by blog's owner", ~m(owner_conn blog)a do
      deleted = owner_conn |> mutation_result(@query, %{id: blog.id}, "deleteBlog")

      assert deleted["id"] == to_string(blog.id)
      assert {:error, _} = ORM.find(Blog, deleted["id"])
    end

    test "can delete a blog by auth user", ~m(blog)a do
      blog = blog |> Repo.preload(:communities)
      belongs_community_title = blog.communities |> List.first() |> Map.get(:title)
      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"blog.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: blog.id}, "deleteBlog")

      assert deleted["id"] == to_string(blog.id)
      assert {:error, _} = ORM.find(Blog, deleted["id"])
    end
  end
end
