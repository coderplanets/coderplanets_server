defmodule GroupherServer.Test.CMS.Hooks.MentionInPost do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]
  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias Helper.ORM
  alias GroupherServer.{CMS, Delivery}

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
      {:ok, post} = preload_author(post)

      {:ok, _result} = Hooks.Mention.handle(post)

      {:ok, result} = Delivery.paged_mentions(user2, %{page: 1, size: 10})

      mention = result.entries |> List.first()
      assert mention.article_id == post.id
      assert mention.title == post.title
      assert mention.user.login == post.author.user.login

      IO.inspect(result, label: "the result")
    end
  end
end
