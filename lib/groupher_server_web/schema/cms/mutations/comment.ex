defmodule GroupherServerWeb.Schema.CMS.Mutations.Comment do
  @moduledoc """
  CMS mutations for comments
  """
  use Helper.GqlSchemaSuite

  object :cms_comment_mutations do
    @desc "write a comment"
    field :create_comment, :comment do
      # TODO use thread and force community pass-in
      arg(:thread, :thread, default_value: :post)
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))

      # TDOO: use a comment resolver
      middleware(M.Authorize, :login)
      # TODO: 文章作者可以删除评论，文章可以设置禁止评论
      resolve(&R.CMS.create_comment/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end

    @desc "update a comment"
    field :update_comment, :comment do
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :comment)
      middleware(M.Passport, claim: "owner")

      resolve(&R.CMS.update_comment/3)
    end

    @desc "delete a comment"
    field :delete_comment, :comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :comment)
      middleware(M.Passport, claim: "owner")

      resolve(&R.CMS.delete_comment/3)
    end

    @desc "reply to a comment"
    field :reply_comment, :comment do
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))

      middleware(M.Authorize, :login)
      # TODO: 文章作者可以删除评论，文章可以设置禁止评论
      resolve(&R.CMS.reply_comment/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end

    @desc "upvote to a comment"
    field :upvote_comment, :comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.upvote_comment/3)
    end

    @desc "undo upvote to a comment"
    field :undo_upvote_comment, :comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.undo_upvote_comment/3)
    end

    @desc "emotion to a comment"
    field :emotion_to_comment, :comment do
      arg(:id, non_null(:id))
      arg(:emotion, non_null(:comment_emotion))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.emotion_to_comment/3)
    end

    @desc "undo emotion to a comment"
    field :undo_emotion_to_comment, :comment do
      arg(:id, non_null(:id))
      arg(:emotion, non_null(:comment_emotion))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.undo_emotion_to_comment/3)
    end

    @desc "mark a comment as question post's best solution"
    field :mark_comment_solution, :comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.mark_comment_solution/3)
    end

    @desc "mark a comment as question post's best solution"
    field :undo_mark_comment_solution, :comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.undo_mark_comment_solution/3)
    end

    @desc "pin a comment"
    field :pin_comment, :comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :comment)
      middleware(M.Passport, claim: "owner")

      resolve(&R.CMS.pin_comment/3)
    end

    @desc "undo pin a comment"
    field :undo_pin_comment, :comment do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :comment)
      middleware(M.Passport, claim: "owner")

      resolve(&R.CMS.undo_pin_comment/3)
    end
  end
end
