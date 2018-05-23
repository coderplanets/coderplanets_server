defmodule MastaniServerWeb.Schema.CMS.Mutation.Comment do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.{Resolvers}
  alias MastaniServerWeb.Middleware, as: M

  object :cms_mutation_comment do
    @desc "create a comment"
    field :create_comment, :comment do
      # TODO use part and force community pass-in
      arg(:part, :cms_part, default_value: :post)
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))

      # TDOO: use a comment resolver
      middleware(M.Authorize, :login)
      # TODO: 文章作者可以删除评论，文章可以设置禁止评论
      resolve(&Resolvers.CMS.create_comment/3)
    end

    field :delete_comment, :comment do
      arg(:part, :cms_part, default_value: :post)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: [:post, :comment])
      # TODO: 文章可以设置禁止评论
      # middleware(M.Passport, claim: "owner;cms->c?->post.comment.delete")
      middleware(M.Passport, claim: "owner")
      # middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.delete_comment/3)
    end

    @desc "reply a exsiting comment"
    field :reply_comment, :comment do
      arg(:part, non_null(:cms_part), default_value: :post)
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))

      middleware(M.Authorize, :login)

      resolve(&Resolvers.CMS.reply_comment/3)
    end

    @desc "like a comment"
    field :like_comment, :comment do
      arg(:part, non_null(:cms_comment), default_value: :post_comment)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.like_comment/3)
    end

    @desc "undo like comment"
    # field :undo_like_comment, :idlike do
    field :undo_like_comment, :comment do
      arg(:part, non_null(:cms_comment), default_value: :post_comment)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.undo_like_comment/3)
    end

    field :dislike_comment, :comment do
      arg(:part, non_null(:cms_comment), default_value: :post_comment)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.dislike_comment/3)
    end

    field :undo_dislike_comment, :comment do
      arg(:part, non_null(:cms_comment), default_value: :post_comment)
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.undo_dislike_comment/3)
    end
  end
end
