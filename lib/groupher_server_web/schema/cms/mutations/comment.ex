defmodule GroupherServerWeb.Schema.CMS.Mutations.Comment do
  @moduledoc """
  CMS mutations for comments
  """
  use Helper.GqlSchemaSuite

  object :cms_comment_mutations do
    @desc "write a comment"
    field :create_article_comment, :article_comment do
      # TODO use thread and force community pass-in
      arg(:thread, :thread, default_value: :post)
      arg(:id, non_null(:id))
      arg(:content, non_null(:string))
      # arg(:mention_users, list_of(:ids))

      # TDOO: use a comment resolver
      middleware(M.Authorize, :login)
      # TODO: 文章作者可以删除评论，文章可以设置禁止评论
      resolve(&R.CMS.create_article_comment/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end

    @desc "update a comment"
    field :update_article_comment, :article_comment do
      arg(:id, non_null(:id))
      arg(:content, non_null(:string))
      # arg(:mention_users, list_of(:ids))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :article_comment)
      middleware(M.Passport, claim: "owner")

      resolve(&R.CMS.update_article_comment/3)
    end

    @desc "delete a comment"
    field :delete_article_comment, :article_comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :article_comment)
      middleware(M.Passport, claim: "owner")

      resolve(&R.CMS.delete_article_comment/3)
    end

    @desc "reply to a comment"
    field :reply_article_comment, :article_comment do
      arg(:id, non_null(:id))
      arg(:content, non_null(:string))

      middleware(M.Authorize, :login)
      # TODO: 文章作者可以删除评论，文章可以设置禁止评论
      resolve(&R.CMS.reply_article_comment/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end

    @desc "emotion to a comment"
    field :emotion_to_comment, :article_comment do
      arg(:id, non_null(:id))
      arg(:emotion, non_null(:article_comment_emotion))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.emotion_to_comment/3)
    end

    @desc "undo emotion to a comment"
    field :undo_emotion_to_comment, :article_comment do
      arg(:id, non_null(:id))
      arg(:emotion, non_null(:article_comment_emotion))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.undo_emotion_to_comment/3)
    end

    @desc "mark a comment as question post's best solution"
    field :mark_comment_solution, :article_comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.mark_comment_solution/3)
    end

    @desc "mark a comment as question post's best solution"
    field :undo_mark_comment_solution, :article_comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.undo_mark_comment_solution/3)
    end

    ############################
    ############################
    ############################
    ############################

    @desc "create a comment"
    field :create_comment, :comment do
      # TODO use thread and force community pass-in
      arg(:community, non_null(:string))
      arg(:thread, :thread, default_value: :post)
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))
      arg(:mention_users, list_of(:ids))

      # TDOO: use a comment resolver
      middleware(M.Authorize, :login)
      # TODO: 文章作者可以删除评论，文章可以设置禁止评论
      resolve(&R.CMS.create_comment/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end

    @desc "update a comment"
    field :update_comment, :comment do
      arg(:id, non_null(:id))
      arg(:thread, :thread, default_value: :post)
      arg(:body, non_null(:string))

      # TDOO: use a comment resolver
      middleware(M.Authorize, :login)
      resolve(&R.CMS.update_comment/3)
    end

    @desc "delete a comment"
    field :delete_comment, :comment do
      arg(:thread, :thread, default_value: :post)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      # middleware(M.PassportLoader, source: [:post, :comment])
      middleware(M.PassportLoader, source: [:arg_thread, :comment])
      # TODO: 文章可以设置禁止评论
      # middleware(M.Passport, claim: "owner;cms->c?->post.comment.delete")
      middleware(M.Passport, claim: "owner")
      # middleware(M.Authorize, :login)
      resolve(&R.CMS.delete_comment/3)
    end

    @desc "reply a exsiting comment"
    field :reply_comment, :comment do
      arg(:community, non_null(:string))
      arg(:thread, non_null(:thread), default_value: :post)
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))
      arg(:mention_users, list_of(:ids))

      middleware(M.Authorize, :login)

      resolve(&R.CMS.reply_comment/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end
  end
end
