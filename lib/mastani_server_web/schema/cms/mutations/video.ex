defmodule MastaniServerWeb.Schema.CMS.Mutations.Video do
  @moduledoc """
  CMS mutations for video
  """
  use Helper.GqlSchemaSuite

  object :cms_video_mutations do
    @desc "create a video"
    field :create_video, :video do
      arg(:title, non_null(:string))
      arg(:poster, non_null(:string))
      arg(:thumbnil, non_null(:string))
      arg(:desc, non_null(:string))
      arg(:duration, non_null(:string))
      arg(:duration_sec, non_null(:integer))

      arg(:source, non_null(:string))
      arg(:link, non_null(:string))
      arg(:original_author, non_null(:string))
      arg(:original_author_link, non_null(:string))
      arg(:publish_at, non_null(:datetime))

      arg(:community_id, non_null(:id))
      arg(:thread, :cms_thread, default_value: :video)
      arg(:tags, list_of(:ids))

      middleware(M.Authorize, :login)
      middleware(M.PublishThrottle)
      # middleware(M.PublishThrottle, interval: 3, hour_limit: 15, day_limit: 30)
      resolve(&R.CMS.create_content/3)
      middleware(M.Statistics.MakeContribute, for: :user)
    end

    @desc "pin a video"
    field :pin_video, :video do
      arg(:id, non_null(:id))
      arg(:thread, :video_thread, default_value: :video)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->video.pin")
      resolve(&R.CMS.pin_content/3)
    end

    @desc "unpin a video"
    field :undo_pin_video, :video do
      arg(:id, non_null(:id))
      arg(:thread, :video_thread, default_value: :video)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->video.undo_pin")
      resolve(&R.CMS.undo_pin_content/3)
    end

    @desc "trash a video, not delete"
    field :trash_video, :video do
      arg(:id, non_null(:id))
      arg(:thread, :video_thread, default_value: :video)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->video.trash")

      resolve(&R.CMS.trash_content/3)
    end

    @desc "trash a video, not delete"
    field :undo_trash_video, :video do
      arg(:id, non_null(:id))
      arg(:thread, :video_thread, default_value: :video)
      arg(:community_id, non_null(:id))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :community)
      middleware(M.Passport, claim: "cms->c?->video.undo_trash")

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
      arg(:poster, :string)
      arg(:thumbnil, :string)
      arg(:desc, :string)
      arg(:duration, :string)
      arg(:duration_sec, :integer)

      arg(:source, :string)
      arg(:link, :string)
      arg(:original_author, :string)
      arg(:original_author_link, :string)
      arg(:publish_at, :datetime)
      arg(:tags, list_of(:ids))

      middleware(M.Authorize, :login)
      middleware(M.PassportLoader, source: :video)
      middleware(M.Passport, claim: "owner;cms->c?->video.edit")

      resolve(&R.CMS.update_content/3)
    end
  end
end
