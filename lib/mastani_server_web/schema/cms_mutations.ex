defmodule MastaniServerWeb.Schema.CMS.Mutations do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers

  object :cms_mutations do
    @desc "hehehef: create a user"
    field :create_post, :post do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))

      resolve(&Resolvers.CMS.create_post/3)
    end

    @desc "star a post"
    field :star_post, :post do
      arg(:post_id, non_null(:id))
      resolve(&Resolvers.CMS.start_post/3)
    end

    @desc "unstar a post"
    field :unstar_post, :post do
      arg(:post_id, non_null(:id))
      resolve(&Resolvers.CMS.unstar_post/3)
    end

    @desc "favorite a post"
    field :favorite_post, :post do
      arg(:post_id, non_null(:id))
      resolve(&Resolvers.CMS.favorite_post/3)
    end

    @desc "unfavorite a post"
    field :unfavorite_post, :post do
      arg(:post_id, non_null(:id))
      resolve(&Resolvers.CMS.unfavorite_post/3)
    end

    @desc "delete a cms/post"
    field :delete_post, :post do
      arg(:post_id, non_null(:id))

      resolve(&Resolvers.CMS.delete_post/3)
    end

    @desc "comment to post"
    field :comment_post, :comment do
      arg(:post_id, non_null(:id))
      arg(:body, non_null(:string))

      resolve(&Resolvers.CMS.comment_post/3)
    end

    @desc "create a comment"
    field :create_comment, :comment do
      arg(:body, non_null(:string))

      # TDOO: use a comment resolver
      resolve(&Resolvers.CMS.create_comment/3)
    end

    @desc "delete a comment"
    field :delete_comment, :comment do
      arg(:id, non_null(:id))

      # TDOO: use a comment resolver
      resolve(&Resolvers.CMS.delete_comment/3)
    end
  end
end
