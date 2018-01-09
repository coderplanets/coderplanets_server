defmodule MastaniServerWeb.Schema.CMSOps do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers
  import Ecto.Query, only: [order_by: 2, first: 2, first: 1]

  # querys
  object :cms_post_queries do
    @desc "hehehef: Get all links"
    field :all_posts, non_null(list_of(non_null(:post))) do
      resolve(&Resolvers.CMS.Post.all_posts/3)
    end
  end

  # mutations
  object :cms_post_mutations do
    @desc "hehehef: create a user"
    field :create_post, :post do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))

      resolve(&Resolvers.CMS.Post.create_post/3)
    end

    @desc "star a post"
    field :star_post, :post do
      arg(:post_id, non_null(:id))
      # not need user id, use current_user
      arg(:user_id, non_null(:id))

      resolve(&Resolvers.CMS.Post.start_post/3)
    end

    @desc "delete a cms/post"
    field :delete_post, :post do
      arg(:post_id, non_null(:id))

      resolve(&Resolvers.CMS.Post.delete_post/3)
    end

    @desc "comment to post"
    field :comment_post, :comment do
      arg(:post_id, non_null(:id))
      arg(:body, non_null(:string))

      resolve(&Resolvers.CMS.Post.comment_post/3)
    end

    @desc "create a comment"
    field :create_comment, :comment do
      arg(:body, non_null(:string))

      # TDOO: use a comment resolver
      resolve(&Resolvers.CMS.Post.create_comment/3)
    end

  end
end
