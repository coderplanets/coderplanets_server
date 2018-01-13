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

    @desc "create a post tag"
    field :create_tag, :tag do
      arg(:title, non_null(:string))
      arg(:type, :cms_part, default_value: :post)

      resolve(&Resolvers.CMS.create_tag/3)
    end

    field :set_tag, :tag do
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      arg(:date, :date)
      arg(:datetime, :datetime)
      arg(:type, :cms_part, default_value: :post)

      resolve(&Resolvers.CMS.set_tag/3)
    end

    field :reaction, :article do
      arg(:id, non_null(:id))
      arg(:type, non_null(:cms_part))
      arg(:action, non_null(:cms_action))
      resolve(&Resolvers.CMS.reaction/3)
    end

    field :undo_reaction, :article do
      arg(:id, non_null(:id))
      arg(:type, non_null(:cms_part))
      arg(:action, non_null(:cms_action))
      resolve(&Resolvers.CMS.undo_reaction/3)
    end

    @desc "delete a cms/post"
    field :delete_post, :post do
      arg(:post_id, non_null(:id))

      resolve(&Resolvers.CMS.delete_post/3)
    end

    @desc "create a comment"
    field :create_comment, :comment do
      arg(:type, non_null(:cms_part), default_value: :post)
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))

      # TDOO: use a comment resolver
      resolve(&Resolvers.CMS.create_comment/3)
    end

    @desc "create a comment"
    field :delete_comment, :comment do
      # arg(:type, non_null(:cms_part), default_value: :post)
      arg(:id, non_null(:id))
      arg(:type, :cms_part, default_value: :post)
      # arg(:body, non_null(:string))

      resolve(&Resolvers.CMS.delete_comment/3)
    end

    # @desc "delete a comment"
    # field :delete_comment, :comment do
    # arg(:id, non_null(:id))

    # TDOO: use a comment resolver
    # resolve(&Resolvers.CMS.delete_comment/3)
    # end
  end
end
