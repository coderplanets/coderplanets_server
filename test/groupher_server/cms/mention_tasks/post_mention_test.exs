defmodule GroupherServer.Test.CMS.MentionTask.Post do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Post, Comment, CitedContent}
  alias CMS.Delegate.MentionTask

  @site_host get_config(:general, :site_host)

  @article_mention_class "cdx-mention"

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, post2} = db_insert(:post)
    {:ok, post3} = db_insert(:post)
    {:ok, post4} = db_insert(:post)
    {:ok, post5} = db_insert(:post)

    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 community post post2 post3 post4 post5 post_attrs)a}
  end

  describe "[cite basic]" do
    @tag :wip
    test "cited multi post should work",
         ~m(user user2 community post2 post3 post4 post5 post_attrs)a do
      body =
        mock_rich_text(
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>),
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>)
        )

      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      MentionTask.handle(post)
    end
  end
end
