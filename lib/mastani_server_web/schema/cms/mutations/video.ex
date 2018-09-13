defmodule MastaniServerWeb.Schema.CMS.Mutations.Video do
  @moduledoc """
  CMS mutations for video
  """
  use Helper.GqlSchemaSuite

  object :cms_video_mutations do
    @desc "create a video"
    field :create_video, :video do
      arg(:title, non_null(:string))
      arg(:body, non_null(:string))
      arg(:digest, non_null(:string))
      arg(:length, non_null(:integer))
      arg(:link_addr, :string)
      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :video)
      arg(:tags, list_of(:ids))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      # middleware(M.PublishThrottle, interval: 3, hour_limit: 15, day_limit: 30)
      resolve(&R.CMS.create_content/3)
    end

    @desc "pin a video"
    field :pin_video, :video do
      arg(:id, non_null(:id))
      arg(:type, :video_type, default_value: :video)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->video.pin")
      resolve(&R.CMS.pin_content/3)
    end

    @desc "unpin a video"
    field :undo_pin_video, :video do
      arg(:id, non_null(:id))
      arg(:type, :video_type, default_value: :video)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->video.undo_pin")
      resolve(&R.CMS.undo_pin_content/3)
    end

    @desc "trash a video, not delete"
    field :trash_video, :video do
      arg(:id, non_null(:id))
      arg(:type, :video_type, default_value: :video)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->video.trash")

      resolve(&R.CMS.trash_content/3)
    end

    @desc "trash a video, not delete"
    field :undo_trash_video, :video do
      arg(:id, non_null(:id))
      arg(:type, :video_type, default_value: :video)

      middleware(M.Authorize, :login)
      middleware(M.Passport, claim: "cms->video.undo_trash")

      resolve(&R.CMS.undo_trash_content/3)
    end

    @desc "delete a cms/video"
    # TODO: if video belongs to multi communities, unset instead delete
    field :delete_video, :video do
      arg(:id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :video)
      middleware(M.Passport, claim: "owner;cms->c?->video.delete")

      resolve(&R.CMS.delete_content/3)
    end

    @desc "update a cms/video"
    field :update_video, :video do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:body, :string)
      arg(:digest, :string)

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :video)
      middleware(M.Passport, claim: "owner;cms->c?->video.edit")

      resolve(&R.CMS.update_content/3)
    end
  end
end
