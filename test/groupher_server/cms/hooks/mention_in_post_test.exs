defmodule GroupherServer.Test.CMS.Hooks.MentionInPost do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Comment}
  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  @article_mention_class "cdx-mention"

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, post} = db_insert(:post)

    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 user3 community post post_attrs)a}
  end

  describe "[mention in post basic]" do
    @tag :wip
    test "mention multi user in post should work", ~m(user user2 user3 community  post_attrs)a do
      body =
        mock_rich_text(
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>, and <div class=#{
            @article_mention_class
          }>#{user3.login}</div>),
          ~s(hi <div class=#{@article_mention_class}>#{user2.login}</div>)
        )

      post_attrs = post_attrs |> Map.merge(%{body: body})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, result} = Hooks.Mention.handle(post)

      assert length(result) == 2
    end
  end
end
