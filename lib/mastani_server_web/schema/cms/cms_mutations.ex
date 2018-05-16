defmodule MastaniServerWeb.Schema.CMS.Mutations do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.{Resolvers}
  alias MastaniServerWeb.Middleware, as: M
  # split into postMutaion, jobMutation ...

  object :cms_mutations do
    @desc "create a global community"
    field :create_community, :community do
      arg(:title, non_null(:string))
      arg(:desc, non_null(:string))
      arg(:raw, non_null(:string))
      arg(:logo, non_null(:string))
      arg(:category, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.create")

      resolve(&Resolvers.CMS.create_community/3)
      # middleware(M.Statistics.MakeContribute, for: :user)
      middleware(M.Statistics.MakeContribute, for: [:user, :community])
    end

    # TODO: update community: category
    @desc "delete a global community"
    field :delete_community, :community do
      arg(:id, non_null(:id))
      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->community.delete")

      resolve(&Resolvers.CMS.delete_community/3)
    end

    @desc "create independent thread"
    field :create_thread, :thread do
      arg(:title, non_null(:string))
      arg(:raw, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->thread.create")

      resolve(&Resolvers.CMS.create_thread/3)
    end

    @desc "link a exist thread to a exist community"
    field :add_thread_to_community, :community do
      arg(:community_id, non_null(:id))
      arg(:thread_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->thread.add")

      resolve(&Resolvers.CMS.add_thread_to_community/3)
    end

    # field :delete_thread_from_community, :community do
    # arg(:community_id, non_null(:id))
    # arg(:thread_id, non_null(:id))

    # middleware(M.Authorize, :login)
    # middleware(M.PassportLoader, source: :community)
    # middleware(M.Passport, claim: "cms->c?->thread.delete")

    # resolve(&Resolvers.CMS.add_thread_to_community/3)
    # end

    @desc "set a editor for a community"
    field :add_cms_editor, :user do
      arg(:community_id, non_null(:id))
      arg(:user_id, non_null(:id))
      arg(:title, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->editor.add")

      resolve(&Resolvers.CMS.add_editor/3)
    end

    @desc "delete a editor from a community, the user's passport also deleted"
    field :delete_cms_editor, :user do
      arg(:community_id, non_null(:id))
      arg(:user_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->editor.delete")

      resolve(&Resolvers.CMS.delete_editor/3)
    end

    # TODO: remove, should remove both editor and cms->passport

    @desc "update cms editor's title, passport is not effected"
    field :update_cms_editor, :user do
      arg(:community_id, non_null(:id))
      arg(:user_id, non_null(:id))
      arg(:title, non_null(:string))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->editor.update")

      resolve(&Resolvers.CMS.update_editor/3)
    end

    # @desc "set passport details for a user TODO: unset"
    # field :set_cms_passport, :user do
    # args(:userId, non_null(:id))
    # args(:detail, non_null(:string))

    # middleware(M.Authorize, :login)
    # middleware(M.Passport, claim: "cms->community.set_editor")

    # resolve(&Resolvers.CMS.stamp_passport/3)
    # end

    @desc "subscribe a community so it can appear in sidebar"
    field :subscribe_community, :community do
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.subscribe_community/3)
    end

    @desc "unsubscribe a community"
    field :unsubscribe_community, :community do
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      resolve(&Resolvers.CMS.unsubscribe_community/3)
    end

    field :create_tag, :tag do
      arg(:title, non_null(:string))
      arg(:color, non_null(:rainbow_color_enum))
      arg(:community_id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->p?.tag.create")

      resolve(&Resolvers.CMS.create_tag/3)
    end

    @desc "delete a tag by part [:login required]"
    field :delete_tag, :tag do
      arg(:id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->p?.tag.delete")

      resolve(&Resolvers.CMS.delete_tag/3)
    end

    @desc "set a tag within community"
    field :set_tag, :tag do
      # part id
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->p?.tag.set")

      resolve(&Resolvers.CMS.set_tag/3)
    end

    field :unset_tag, :tag do
      # part id
      arg(:id, non_null(:id))
      arg(:tag_id, non_null(:id))
      arg(:community_id, non_null(:id))
      arg(:part, :cms_part, default_value: :post)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->p?.tag.set")

      resolve(&Resolvers.CMS.unset_tag/3)
    end

    # TODO: use community loader
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
