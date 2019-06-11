defmodule GroupherServerWeb.Schema.CMS.Mutations.Comment do
  @moduledoc """
  CMS mutations for comments
  """
  use Helper.GqlSchemaSuite

  object :cms_comment_mutations do
    @desc "create a comment"
    field :create_comment, :comment do
      # TODO use thread and force community pass-in
      arg(:community, non_null(:string))
      arg(:thread, :cms_thread, default_value: :post)
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
      arg(:thread, :cms_thread, default_value: :post)
      arg(:body, non_null(:string))

      # TDOO: use a comment resolver
      middleware(M.Authorize, :login)
      resolve(&R.CMS.update_comment/3)
    end

    @desc "delete a comment"
    field :delete_comment, :comment do
      arg(:thread, :cms_thread, default_value: :post)
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
      arg(:thread, non_null(:cms_thread), default_value: :post)
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))
      arg(:mention_users, list_of(:ids))

      middleware(M.Authorize, :login)

      resolve(&R.CMS.reply_comment/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end

    @desc "like a comment"
    field :like_comment, :comment do
      arg(:thread, non_null(:cms_comment), default_value: :post_comment)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.like_comment/3)
    end

    @desc "undo like comment"
    # field :undo_like_comment, :idlike do
    field :undo_like_comment, :comment do
      arg(:thread, non_null(:cms_comment), default_value: :post_comment)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.undo_like_comment/3)
    end

    field :dislike_comment, :comment do
      arg(:thread, non_null(:cms_comment), default_value: :post_comment)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.dislike_comment/3)
    end

    field :undo_dislike_comment, :comment do
      arg(:thread, non_null(:cms_comment), default_value: :post_comment)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&R.CMS.undo_dislike_comment/3)
    end
  end
end
