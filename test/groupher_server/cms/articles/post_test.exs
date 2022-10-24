defmodule GroupherServer.Test.CMS.Articles.Post do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}
  alias Helper.Converter.{EditorToHTML, HtmlSanitizer}

  alias EditorToHTML.{Class, Validator}
  alias CMS.Model.{Author, ArticleDocument, Community, Post, PostDocument}

  @root_class Class.article()
  @last_year Timex.shift(Timex.beginning_of_year(Timex.now()), days: -3, seconds: -1)
  @article_digest_length get_config(:article, :digest_length)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 community post post_attrs)a}
  end

  describe "[cms post curd]" do
    test "can create post with valid attrs", ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      post = Repo.preload(post, :document)

      body_map = Jason.decode!(post.document.body)

      assert post.meta.thread == "POST"

      assert post.title == post_attrs.title
      assert body_map |> Validator.is_valid()

      assert post.document.body_html
             |> String.contains?(~s(<div class="#{@root_class["viewer"]}">))

      assert post.document.body_html |> String.contains?(~s(<p id="block-))

      paragraph_text = body_map["blocks"] |> List.first() |> get_in(["data", "text"])

      assert post.digest ==
               paragraph_text
               |> HtmlSanitizer.strip_all_tags()
               |> String.slice(0, @article_digest_length)
    end

    test "created post should have a acitve_at field, same with inserted_at",
         ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      assert post.active_at == post.inserted_at
    end

    @tag :wip
    test "read post should update views and meta viewed_user_list",
         ~m(post_attrs community user user2)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      # same user duplicate case
      {:ok, _} = CMS.read_article(:post, post.id, user)
      {:ok, created} = ORM.find(Post, post.id)

      assert created.meta.viewed_user_ids |> length == 1
      assert user.id in created.meta.viewed_user_ids

      {:ok, _} = CMS.read_article(:post, post.id, user2)
      {:ok, created} = ORM.find(Post, post.id)

      assert created.meta.viewed_user_ids |> length == 2
      assert user.id in created.meta.viewed_user_ids
      assert user2.id in created.meta.viewed_user_ids
    end

    test "read post should contains viewer_has_xxx state", ~m(post_attrs community user user2)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post} = CMS.read_article(:post, post.id, user)

      assert not post.viewer_has_collected
      assert not post.viewer_has_upvoted
      assert not post.viewer_has_reported

      {:ok, post} = CMS.read_article(:post, post.id)

      assert not post.viewer_has_collected
      assert not post.viewer_has_upvoted
      assert not post.viewer_has_reported

      {:ok, post} = CMS.read_article(:post, post.id, user2)

      assert not post.viewer_has_collected
      assert not post.viewer_has_upvoted
      assert not post.viewer_has_reported

      {:ok, _} = CMS.upvote_article(:post, post.id, user)
      {:ok, _} = CMS.collect_article(:post, post.id, user)
      {:ok, _} = CMS.report_article(:post, post.id, "reason", "attr_info", user)

      {:ok, post} = CMS.read_article(:post, post.id, user)

      assert post.viewer_has_collected
      assert post.viewer_has_upvoted
      assert post.viewer_has_reported
    end

    test "add user to cms authors, if the user is not exsit in cms authors",
         ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      {:ok, _} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, author} = ORM.find_by(Author, user_id: user.id)
      assert author.user_id == user.id
    end

    test "create post with an non-exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:post, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_article(ivalid_community, :post, invalid_attrs, user)
    end
  end

  describe "[cms post sink/undo_sink]" do
    test "if a post is too old, read post should update can_undo_sink flag",
         ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      assert post.meta.can_undo_sink

      {:ok, post_last_year} = db_insert(:post, %{title: "last year", inserted_at: @last_year})
      {:ok, post_last_year} = CMS.read_article(:post, post_last_year.id)
      assert not post_last_year.meta.can_undo_sink

      {:ok, post_last_year} = CMS.read_article(:post, post_last_year.id, user)
      assert not post_last_year.meta.can_undo_sink
    end

    test "can sink a post", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      assert not post.meta.is_sinked

      {:ok, post} = CMS.sink_article(:post, post.id)
      assert post.meta.is_sinked
      assert post.active_at == post.inserted_at
    end

    test "can undo sink post", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post} = CMS.sink_article(:post, post.id)
      assert post.meta.is_sinked
      assert post.meta.last_active_at == post.active_at

      {:ok, post} = CMS.undo_sink_article(:post, post.id)
      assert not post.meta.is_sinked
      assert post.active_at == post.meta.last_active_at
    end

    test "can not undo sink to old post", ~m()a do
      {:ok, post_last_year} = db_insert(:post, %{title: "last year", inserted_at: @last_year})

      {:error, reason} = CMS.undo_sink_article(:post, post_last_year.id)
      is_error?(reason, :undo_sink_old_article)
    end
  end

  describe "[cms post question]" do
    test "post have default question flags", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      assert not post.is_question
      assert not post.is_solved
    end

    test "can create post with question", ~m(user community post_attrs)a do
      post_attrs = Map.merge(post_attrs, %{is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      assert post.is_question
    end

    test "can update post with question", ~m(user community post_attrs)a do
      post_attrs = Map.merge(post_attrs, %{is_question: true})
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      assert post.is_question

      {:ok, post} = CMS.update_article(post, %{is_question: false})
      assert not post.is_question
    end
  end

  describe "[cms post document]" do
    test "will create related document after create", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post} = CMS.read_article(:post, post.id)
      assert not is_nil(post.document.body_html)
      {:ok, post} = CMS.read_article(:post, post.id, user)
      assert not is_nil(post.document.body_html)

      {:ok, article_doc} = ORM.find_by(ArticleDocument, %{article_id: post.id, thread: "POST"})
      {:ok, post_doc} = ORM.find_by(PostDocument, %{post_id: post.id})

      assert post.document.body == post_doc.body
      assert article_doc.body == post_doc.body
    end

    test "delete post should also delete related document", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _article_doc} = ORM.find_by(ArticleDocument, %{article_id: post.id, thread: "POST"})
      {:ok, _post_doc} = ORM.find_by(PostDocument, %{post_id: post.id})

      {:ok, _} = CMS.delete_article(post)

      {:error, _} = ORM.find(Post, post.id)
      {:error, _} = ORM.find_by(ArticleDocument, %{article_id: post.id, thread: "POST"})
      {:error, _} = ORM.find_by(PostDocument, %{post_id: post.id})
    end

    test "update post should also update related document", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      body = mock_rich_text(~s(new content))
      {:ok, post} = CMS.update_article(post, %{body: body})

      {:ok, article_doc} = ORM.find_by(ArticleDocument, %{article_id: post.id, thread: "POST"})
      {:ok, post_doc} = ORM.find_by(PostDocument, %{post_id: post.id})

      assert String.contains?(post_doc.body, "new content")
      assert String.contains?(article_doc.body, "new content")
    end
  end
end
