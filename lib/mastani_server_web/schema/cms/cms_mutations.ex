defmodule MastaniServerWeb.Schema.CMS.Mutations do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.{Resolvers}
  alias MastaniServerWeb.Middleware, as: M

  object :cms_mutations do
    @desc "create a user"
    field :create_post, :post do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:digest, non_null(:string))
      arg(:length, non_null(:integer))
      arg(:link_addr, :string)
      arg(:community, non_null(:string))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.create_post/3)
    end

    @desc "create a tag by part [:login required]"
    field :create_tag, :tag do
      arg(:title, non_null(:string))
      arg(:color, non_null(:rainbow_color_enum))
      arg(:community, non_null(:string))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->c?->p?.tag.create")

      resolve(&Resolvers.CMS.create_tag/3)
    end

    @desc "delete a tag by part [:login required]"
    field :delete_tag, :tag do
      arg(:id, non_null(:id))
      arg(:community, non_null(:string))
      # arg(:tag, non_null(:string))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->c?->p?.tag.delete")

      resolve(&Resolvers.CMS.delete_tag/3)
    end

    field :create_community, :community do
      arg(:title, non_null(:string))
      arg(:desc, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.create")

      resolve(&Resolvers.CMS.create_community/3)
      # middleware(M.Statistics.MakeContribute, for: :user)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    field :delete_community, :community do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.delete")

      resolve(&Resolvers.CMS.delete_community/3)
    end

    @desc "subscribe a community so it can appear in sidebar"
    field :subscribe_community, :community_subscriber do
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.subscribe_community/3)
    end

    @desc "unsubscribe a community"
    field :unsubscribe_community, :community_subscriber do
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.unsubscribe_community/3)
    end

    @desc "set a tag within community"
    field :set_tag, :tag do
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      arg(:community, non_null(:string))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->c?->p?.tag.set")

      resolve(&Resolvers.CMS.set_tag/3)
    end

    field :unset_tag, :tag do
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      arg(:community, non_null(:string))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->c?->p?.tag.set")

      resolve(&Resolvers.CMS.unset_tag/3)
    end

    field :set_community, :community do
      arg(:id, non_null(:id))
      arg(:community, non_null(:string))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->p?.community.set")
      resolve(&Resolvers.CMS.set_community/3)
    end

    field :unset_community, :community do
      arg(:id, non_null(:id))
      arg(:community, non_null(:string))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->p?.community.set")
      resolve(&Resolvers.CMS.unset_community/3)
    end

    field :reaction, :article do
      arg(:id, non_null(:id))
      arg(:part, non_null(:cms_part))
      arg(:action, non_null(:cms_action))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.reaction/3)
    end

    field :undo_reaction, :article do
      arg(:id, non_null(:id))
      arg(:part, non_null(:cms_part))
      arg(:action, non_null(:cms_action))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.undo_reaction/3)
    end

    @desc "delete a cms/post"
    field :delete_post, :post do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post)
      middleware(M.Passport, claim: "owner;cms->c?->post.article.delete")

      resolve(&Resolvers.CMS.delete_post/3)
    end

    @desc "update a cms/post"
    field :update_post, :post do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)

      middlewared(M.Authorize, :login)
      middleware(M.PassportLoader, source: :post)
      middleware(M.Passport, claim: "owner;cms->c?->post.article.edit")

      resolve(&Resolvers.CMS.update_post/3)
    end

    # TODO: set community, tag ...
    @desc "create a comment"
    field :create_comment, :comment do
      # TODO use part and force community pass-in
      arg(:part, non_null(:cms_part), default_value: :post)
      arg(:id, non_null(:id))
      arg(:body, non_null(:string))

      # TDOO: use a comment resolver
      middleware(M.Authorize, :login)
      # TODO: 文章作者可以删除评论，文章可以设置禁止评论
      resolve(&Resolvers.CMS.create_comment/3)
    end

    @desc "create a comment"
    field :delete_comment, :comment do
      # arg(:type, non_null(:cms_part), default_value: :post)
      arg(:id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)
      # arg(:body, non_null(:string))

      middleware(M.Authorize, :login)
      # middleware(M.OwnerRequired, match: [:post, :comment])
      middleware(M.PassportLoader, source: [:post, :comment])
      # TODO: 文章作者可以删除评论，文章可以设置禁止评论
      # middleware(M.Passport, claim: "owner;parent;cms->c?->post.comment.delete")
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
