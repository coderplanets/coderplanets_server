defmodule MastaniServerWeb.Schema.CMS.PostTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers

  # TODO: remove ()
  object :post do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :body, non_null(:string)
    field :author, :author, resolve: assoc(:author)
  end

  object :author do
    field :id, non_null(:id)
    field :role, :string
    field :posts, list_of(:post), resolve: assoc(:posts)
  end

  object :cms_post_queries do
    @desc "hehehef: Get all links"
    field :all_posts, non_null(list_of(non_null(:post))) do
      resolve(&Resolvers.CMS.Post.all_posts/3)
    end
  end

  object :cms_post_mutations do
    @desc "hehehef: create a user"
    field :create_post, :post do
      arg :title, non_null(:string)
      arg :body, non_null(:string)
      arg :user_id, non_null(:id)

      resolve(&Resolvers.CMS.Post.create_post/3)
    end
  end

end
