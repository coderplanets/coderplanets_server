defmodule GroupherServer.Test.Query.Hooks.CiteBlog do
  @moduledoc false

  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS

  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, blog} = db_insert(:blog)
    {:ok, user} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    blog_attrs = mock_attrs(:blog, %{community_id: community.id})

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community blog blog_attrs user)a}
  end

  describe "[query paged_blogs filter pagination]" do
    # id
    @query """
    query($content: Content!, $id: ID!, $filter: PageFilter!) {
      pagedCitingContents(id: $id, content: $content, filter: $filter) {
        entries {
          id
          title
          user {
            login
            nickname
            avatar
          }
          commentId
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """

    test "should get paged cittings", ~m(guest_conn community blog_attrs user)a do
      {:ok, blog2} = db_insert(:blog)

      {:ok, comment} =
        CMS.create_comment(
          :blog,
          blog2.id,
          mock_comment(~s(the <a href=#{@site_host}/blog/#{blog2.id} />)),
          user
        )

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/blog/#{blog2.id} />),
          ~s(the <a href=#{@site_host}/blog/#{blog2.id} />)
        )

      blog_attrs = blog_attrs |> Map.merge(%{body: body})
      {:ok, blog_x} = CMS.create_article(community, :blog, blog_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/blog/#{blog2.id} />))
      blog_attrs = blog_attrs |> Map.merge(%{body: body})
      {:ok, blog_y} = CMS.create_article(community, :blog, blog_attrs, user)

      Hooks.Cite.handle(blog_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(blog_y)

      variables = %{content: "BLOG", id: blog2.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedCitingContents")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 3
    end
  end
end
