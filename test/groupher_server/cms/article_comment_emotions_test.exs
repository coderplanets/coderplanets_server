defmodule GroupherServer.Test.CMS.ArticleCommentEmotions do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.{ArticleComment, ArticleCommentEmotion, Post}

  @max_replies_count ArticleComment.max_replies_count()
  @default_emotions ArticleCommentEmotion.default_emotions()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)

    {:ok, ~m(user user2 post job)a}
  end

  describe "[basic article comment emotion]" do
    @tag :wip
    test "comment has default emotions after created", ~m(post user user2)a do
      parent_content = "parent comment"

      {:ok, parent_comment} = CMS.write_comment(:post, post.id, parent_content, user)
      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)

      emotions = parent_comment.emotions |> Map.from_struct() |> Map.delete(:id)
      assert @default_emotions == emotions
    end

    @tag :wip2
    test "can make emotion to comment", ~m(post user user2)a do
      parent_content = "parent comment-"
      {:ok, parent_comment} = CMS.write_comment(:post, post.id, parent_content, user)

      {:ok, _} = CMS.make_emotion(parent_comment.id, "", user)
      # {:ok, _} = CMS.make_emotion(parent_comment.id, "", user)
      # {:ok, _} = CMS.make_emotion(parent_comment.id, "", user)

      {:ok, parent_comment} = ORM.find(ArticleComment, parent_comment.id)
      # IO.inspect(parent_comment.emotions, label: "the parent_comment")
    end
  end
end
