defmodule GroupherServer.Test.Articles.Guide do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Repo}
  alias Helper.Converter.{EditorToHTML, HtmlSanitizer}

  alias EditorToHTML.{Class, Validator}
  alias CMS.Model.{Author, Guide, Community, ArticleDocument, GuideDocument}
  alias Helper.ORM

  @root_class Class.article()
  @last_year Timex.shift(Timex.beginning_of_year(Timex.now()), days: -3, seconds: -1)
  @article_digest_length get_config(:article, :digest_length)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guide_attrs = mock_attrs(:guide, %{community_id: community.id})

    {:ok, ~m(user user2 community guide_attrs)a}
  end

  describe "[cms guides curd]" do
    test "can create guide with valid attrs", ~m(user community guide_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      guide = Repo.preload(guide, :document)

      body_map = Jason.decode!(guide.document.body)

      assert guide.meta.thread == "GUIDE"

      assert guide.title == guide_attrs.title
      assert body_map |> Validator.is_valid()

      assert guide.document.body_html
             |> String.contains?(~s(<div class="#{@root_class["viewer"]}">))

      assert guide.document.body_html |> String.contains?(~s(<p id="block-))

      paragraph_text = body_map["blocks"] |> List.first() |> get_in(["data", "text"])

      assert guide.digest ==
               paragraph_text
               |> HtmlSanitizer.strip_all_tags()
               |> String.slice(0, @article_digest_length)
    end

    test "created guide should have a acitve_at field, same with inserted_at",
         ~m(user community guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      assert guide.active_at == guide.inserted_at
    end

    test "read guide should update views and meta viewed_user_list",
         ~m(guide_attrs community user user2)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _} = CMS.read_article(:guide, guide.id, user)
      {:ok, _created} = ORM.find(Guide, guide.id)

      # same user duplicate case
      {:ok, _} = CMS.read_article(:guide, guide.id, user)
      {:ok, created} = ORM.find(Guide, guide.id)

      assert created.meta.viewed_user_ids |> length == 1
      assert user.id in created.meta.viewed_user_ids

      {:ok, _} = CMS.read_article(:guide, guide.id, user2)
      {:ok, created} = ORM.find(Guide, guide.id)

      assert created.meta.viewed_user_ids |> length == 2
      assert user.id in created.meta.viewed_user_ids
      assert user2.id in created.meta.viewed_user_ids
    end

    test "read guide should contains viewer_has_xxx state",
         ~m(guide_attrs community user user2)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, guide} = CMS.read_article(:guide, guide.id, user)

      assert not guide.viewer_has_collected
      assert not guide.viewer_has_upvoted
      assert not guide.viewer_has_reported

      {:ok, guide} = CMS.read_article(:guide, guide.id)

      assert not guide.viewer_has_collected
      assert not guide.viewer_has_upvoted
      assert not guide.viewer_has_reported

      {:ok, guide} = CMS.read_article(:guide, guide.id, user2)

      assert not guide.viewer_has_collected
      assert not guide.viewer_has_upvoted
      assert not guide.viewer_has_reported

      {:ok, _} = CMS.upvote_article(:guide, guide.id, user)
      {:ok, _} = CMS.collect_article(:guide, guide.id, user)
      {:ok, _} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)

      {:ok, guide} = CMS.read_article(:guide, guide.id, user)

      assert guide.viewer_has_collected
      assert guide.viewer_has_upvoted
      assert guide.viewer_has_reported
    end

    test "create guide with an exsit community fails", ~m(user)a do
      invalid_attrs = mock_attrs(:guide, %{community_id: non_exsit_id()})
      ivalid_community = %Community{id: non_exsit_id()}

      assert {:error, _} = CMS.create_article(ivalid_community, :guide, invalid_attrs, user)
    end
  end

  describe "[cms guide sink/undo_sink]" do
    test "if a guide is too old, read guide should update can_undo_sink flag",
         ~m(user community guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      assert guide.meta.can_undo_sink

      {:ok, guide_last_year} = db_insert(:guide, %{title: "last year", inserted_at: @last_year})
      {:ok, guide_last_year} = CMS.read_article(:guide, guide_last_year.id)
      assert not guide_last_year.meta.can_undo_sink

      {:ok, guide_last_year} = CMS.read_article(:guide, guide_last_year.id, user)
      assert not guide_last_year.meta.can_undo_sink
    end

    test "can sink a guide", ~m(user community guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      assert not guide.meta.is_sinked

      {:ok, guide} = CMS.sink_article(:guide, guide.id)
      assert guide.meta.is_sinked
      assert guide.active_at == guide.inserted_at
    end

    test "can undo sink guide", ~m(user community guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, guide} = CMS.sink_article(:guide, guide.id)
      assert guide.meta.is_sinked
      assert guide.meta.last_active_at == guide.active_at

      {:ok, guide} = CMS.undo_sink_article(:guide, guide.id)
      assert not guide.meta.is_sinked
      assert guide.active_at == guide.meta.last_active_at
    end

    test "can not undo sink to old guide", ~m()a do
      {:ok, guide_last_year} = db_insert(:guide, %{title: "last year", inserted_at: @last_year})

      {:error, reason} = CMS.undo_sink_article(:guide, guide_last_year.id)
      is_error?(reason, :undo_sink_old_article)
    end
  end

  describe "[cms guide document]" do
    test "will create related document after create", ~m(user community guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, guide} = CMS.read_article(:guide, guide.id)
      assert not is_nil(guide.document.body_html)
      {:ok, guide} = CMS.read_article(:guide, guide.id, user)
      assert not is_nil(guide.document.body_html)

      {:ok, article_doc} = ORM.find_by(ArticleDocument, %{article_id: guide.id, thread: "GUIDE"})
      {:ok, guide_doc} = ORM.find_by(GuideDocument, %{guide_id: guide.id})

      assert guide.document.body == guide_doc.body
      assert article_doc.body == guide_doc.body
    end

    test "delete guide should also delete related document", ~m(user community guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _article_doc} = ORM.find_by(ArticleDocument, %{article_id: guide.id, thread: "GUIDE"})
      {:ok, _guide_doc} = ORM.find_by(GuideDocument, %{guide_id: guide.id})

      {:ok, _} = CMS.delete_article(guide)

      {:error, _} = ORM.find(Guide, guide.id)
      {:error, _} = ORM.find_by(ArticleDocument, %{article_id: guide.id, thread: "GUIDE"})
      {:error, _} = ORM.find_by(GuideDocument, %{guide_id: guide.id})
    end

    test "update guide should also update related document", ~m(user community guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      body = mock_rich_text(~s(new content))
      {:ok, guide} = CMS.update_article(guide, %{body: body})

      {:ok, article_doc} = ORM.find_by(ArticleDocument, %{article_id: guide.id, thread: "GUIDE"})
      {:ok, guide_doc} = ORM.find_by(GuideDocument, %{guide_id: guide.id})

      assert String.contains?(guide_doc.body, "new content")
      assert String.contains?(article_doc.body, "new content")
    end
  end
end
