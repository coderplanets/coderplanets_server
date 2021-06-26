defmodule GroupherServer.Test.CMS.Hooks.CiteDrink do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Drink, Comment, CitedArtiment}
  alias CMS.Delegate.Hooks

  @site_host get_config(:general, :site_host)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, drink} = db_insert(:drink)
    {:ok, drink2} = db_insert(:drink)
    {:ok, drink3} = db_insert(:drink)
    {:ok, drink4} = db_insert(:drink)
    {:ok, drink5} = db_insert(:drink)

    {:ok, community} = db_insert(:community)

    drink_attrs = mock_attrs(:drink, %{community_id: community.id})

    {:ok, ~m(user user2 community drink drink2 drink3 drink4 drink5 drink_attrs)a}
  end

  describe "[cite basic]" do
    test "cited multi drink should work",
         ~m(user community drink2 drink3 drink4 drink5 drink_attrs)a do
      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/drink/#{drink2.id} /> and <a href=#{@site_host}/drink/#{
            drink2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/drink/#{drink3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/drink/#{drink2.id} class=#{drink2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/drink/#{drink4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/drink/#{
            drink5.id
          }> again</a>)
        )

      drink_attrs = drink_attrs |> Map.merge(%{body: body})
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/drink/#{drink3.id} />))
      drink_attrs = drink_attrs |> Map.merge(%{body: body})
      {:ok, drink_n} = CMS.create_article(community, :drink, drink_attrs, user)

      Hooks.Cite.handle(drink)
      Hooks.Cite.handle(drink_n)

      {:ok, drink2} = ORM.find(Drink, drink2.id)
      {:ok, drink3} = ORM.find(Drink, drink3.id)
      {:ok, drink4} = ORM.find(Drink, drink4.id)
      {:ok, drink5} = ORM.find(Drink, drink5.id)

      assert drink2.meta.citing_count == 1
      assert drink3.meta.citing_count == 2
      assert drink4.meta.citing_count == 1
      assert drink5.meta.citing_count == 1
    end

    test "cited drink itself should not work", ~m(user community drink_attrs)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

      body = mock_rich_text(~s(the <a href=#{@site_host}/drink/#{drink.id} />))
      {:ok, drink} = CMS.update_article(drink, %{body: body})

      Hooks.Cite.handle(drink)

      {:ok, drink} = ORM.find(Drink, drink.id)
      assert drink.meta.citing_count == 0
    end

    test "cited comment itself should not work", ~m(user drink)a do
      {:ok, cited_comment} = CMS.create_comment(:drink, drink.id, mock_rich_text("hello"), user)

      {:ok, comment} =
        CMS.update_comment(
          cited_comment,
          mock_comment(
            ~s(the <a href=#{@site_host}/drink/#{drink.id}?comment_id=#{cited_comment.id} />)
          )
        )

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 0
    end

    test "can cite drink's comment in drink", ~m(community user drink drink2 drink_attrs)a do
      {:ok, comment} = CMS.create_comment(:drink, drink.id, mock_rich_text("hello"), user)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/drink/#{drink2.id}?comment_id=#{comment.id} />)
        )

      drink_attrs = drink_attrs |> Map.merge(%{body: body})

      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      Hooks.Cite.handle(drink)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: comment.id})

      # 被 drink 以 comment link 的方式引用了
      assert cited_content.drink_id == drink.id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cite a comment in a comment", ~m(user drink)a do
      {:ok, cited_comment} = CMS.create_comment(:drink, drink.id, mock_rich_text("hello"), user)

      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/drink/#{drink.id}?comment_id=#{cited_comment.id} />)
        )

      {:ok, comment} = CMS.create_comment(:drink, drink.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, cited_comment} = ORM.find(Comment, cited_comment.id)
      assert cited_comment.meta.citing_count == 1

      {:ok, cited_content} = ORM.find_by(CitedArtiment, %{cited_by_id: cited_comment.id})
      assert comment.id == cited_content.comment_id
      assert cited_comment.id == cited_content.cited_by_id
      assert cited_content.cited_by_type == "COMMENT"
    end

    test "can cited drink inside a comment", ~m(user drink drink2 drink3 drink4 drink5)a do
      comment_body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/drink/#{drink2.id} /> and <a href=#{@site_host}/drink/#{
            drink2.id
          }>same la</a> is awesome, the <a href=#{@site_host}/drink/#{drink3.id}></a> is awesome too.),
          # second paragraph
          ~s(the paragraph 2 <a href=#{@site_host}/drink/#{drink2.id} class=#{drink2.title}> again</a>, the paragraph 2 <a href=#{
            @site_host
          }/drink/#{drink4.id}> again</a>, the paragraph 2 <a href=#{@site_host}/drink/#{
            drink5.id
          }> again</a>)
        )

      {:ok, comment} = CMS.create_comment(:drink, drink.id, comment_body, user)
      Hooks.Cite.handle(comment)

      comment_body = mock_rich_text(~s(the <a href=#{@site_host}/drink/#{drink3.id} />))
      {:ok, comment} = CMS.create_comment(:drink, drink.id, comment_body, user)

      Hooks.Cite.handle(comment)

      {:ok, drink2} = ORM.find(Drink, drink2.id)
      {:ok, drink3} = ORM.find(Drink, drink3.id)
      {:ok, drink4} = ORM.find(Drink, drink4.id)
      {:ok, drink5} = ORM.find(Drink, drink5.id)

      assert drink2.meta.citing_count == 1
      assert drink3.meta.citing_count == 2
      assert drink4.meta.citing_count == 1
      assert drink5.meta.citing_count == 1
    end
  end

  describe "[cite pagi]" do
    test "can get paged cited articles.", ~m(user community drink2 drink_attrs)a do
      {:ok, comment} =
        CMS.create_comment(
          :drink,
          drink2.id,
          mock_comment(~s(the <a href=#{@site_host}/drink/#{drink2.id} />)),
          user
        )

      Process.sleep(1000)

      body =
        mock_rich_text(
          ~s(the <a href=#{@site_host}/drink/#{drink2.id} />),
          ~s(the <a href=#{@site_host}/drink/#{drink2.id} />)
        )

      drink_attrs = drink_attrs |> Map.merge(%{body: body})
      {:ok, drink_x} = CMS.create_article(community, :drink, drink_attrs, user)

      Process.sleep(1000)
      body = mock_rich_text(~s(the <a href=#{@site_host}/drink/#{drink2.id} />))
      drink_attrs = drink_attrs |> Map.merge(%{body: body})
      {:ok, drink_y} = CMS.create_article(community, :drink, drink_attrs, user)

      Hooks.Cite.handle(drink_x)
      Hooks.Cite.handle(comment)
      Hooks.Cite.handle(drink_y)

      {:ok, result} = CMS.paged_citing_contents("DRINK", drink2.id, %{page: 1, size: 10})

      entries = result.entries

      result_comment = entries |> List.first()
      result_drink_x = entries |> Enum.at(1)
      result_drink_y = entries |> List.last()

      article_map_keys = [:block_linker, :id, :inserted_at, :thread, :title, :user]

      assert result_comment.comment_id == comment.id
      assert result_comment.id == drink2.id
      assert result_comment.title == drink2.title

      assert result_drink_x.id == drink_x.id
      assert result_drink_x.block_linker |> length == 2
      assert result_drink_x |> Map.keys() == article_map_keys

      assert result_drink_y.id == drink_y.id
      assert result_drink_y.block_linker |> length == 1
      assert result_drink_y |> Map.keys() == article_map_keys

      assert result |> is_valid_pagination?(:raw)
      assert result.total_count == 3
    end
  end
end
