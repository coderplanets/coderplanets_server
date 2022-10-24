defmodule GroupherServer.Test.Query.Hooks.PostCiting do
  @moduledoc false

  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS

  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)

    {:ok, community} = db_insert(:community)
    post_attrs = mock_attrs(:post, %{community_id: community.id})

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community post post_attrs user)a}
  end

  describe "[query paged_posts filter pagination]" do
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
    test "should get paged cittings", ~m(guest_conn community post_attrs user)a do
      {:ok, post2} = db_insert(:post)

      {:ok, comment} =
        CMS.create_comment(
          :post,
          post2.id,
          mock_comment(~s(the <a href=#{@site_host}/post/#{post2.id} />)),
          user
        )

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/post/#{post2.id} />),
          ~s(the <a href=#{@site_host}/post/#{post2.id} />)
        )

      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post_x} = CMS.create_article(community, :post, post_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/post/#{post2.id} />))
      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post_y} = CMS.create_article(community, :post, post_attrs, user)

      Hooks.Cite.handle(post_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(post_y)

      variables = %{content: "POST", id: post2.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedCitingContents")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 3
    end
  end
end
