defmodule MastaniServerWeb.Schema.Utils.Helper do
  @moduledoc """
  common fields
  """
  import Helper.Utils, only: [get_config: 2]
  @page_size get_config(:general, :page_size)
  # @default_inner_page_size 5

  defmacro timestamp_fields do
    quote do
      field(:inserted_at, :datetime)
      field(:updated_at, :datetime)
    end
  end

  # see: https://github.com/absinthe-graphql/absinthe/issues/363
  defmacro pagination_args do
    quote do
      field(:page, :integer, default_value: 1)
      field(:size, :integer, default_value: unquote(@page_size))
    end
  end

  defmacro pagination_fields do
    quote do
      field(:total_count, :integer)
      field(:page_size, :integer)
      field(:total_pages, :integer)
      field(:page_number, :integer)
    end
  end

  defmacro sscial_fields do
    quote do
      field(:qq, :string)
      field(:weibo, :string)
      field(:weichat, :string)
      field(:github, :string)
      field(:zhihu, :string)
      field(:douban, :string)
      field(:twitter, :string)
      field(:facebook, :string)
      field(:dribble, :string)
      field(:instagram, :string)
      field(:pinterest, :string)
      field(:huaban, :string)
    end
  end

  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  alias MastaniServer.CMS
  alias MastaniServerWeb.Resolvers, as: R
  alias MastaniServerWeb.Middleware, as: M

  # fields for: favorite count, favorited_users, viewer_did_favorite..
  defmacro favorite_fields(thread) do
    quote do
      @doc "if viewer has favroted of this #{unquote(thread)}"
      field :viewer_has_favorited, :boolean do
        arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

        middleware(M.Authorize, :login)
        middleware(M.PutCurrentUser)
        resolve(dataloader(CMS, :favorites))
        middleware(M.ViewerDidConvert)
      end

      @doc "favroted count of this #{unquote(thread)}"
      field :favorited_count, :integer do
        arg(:count, :count_type, default_value: :count)

        arg(
          :type,
          unquote(String.to_atom("#{to_string(thread)}_thread")),
          default_value: unquote(thread)
        )

        resolve(dataloader(CMS, :favorites))
        middleware(M.ConvertToInt)
      end

      @doc "list of user who has favroted this #{unquote(thread)}"
      field :favorited_users, list_of(:user) do
        arg(:filter, :members_filter)

        middleware(M.PageSizeProof)
        resolve(dataloader(CMS, :favorites))
      end

      @doc "get viewer's favroted category if seted"
      field :favorited_category_id, :id do
        arg(
          :thread,
          unquote(String.to_atom("#{to_string(thread)}_thread")),
          default_value: unquote(thread)
        )

        middleware(M.Authorize, :login)
        resolve(&R.CMS.favorited_category/3)
      end
    end
  end

  # fields for: star count, users, viewer_did_starred..
  defmacro star_fields(thread) do
    quote do
      field :viewer_has_starred, :boolean do
        arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

        middleware(M.Authorize, :login)
        middleware(M.PutCurrentUser)
        resolve(dataloader(CMS, :stars))
        middleware(M.ViewerDidConvert)
      end

      field :starred_count, :integer do
        arg(:count, :count_type, default_value: :count)

        arg(
          :type,
          unquote(String.to_atom("#{to_string(thread)}_thread")),
          default_value: unquote(thread)
        )

        resolve(dataloader(CMS, :stars))
        middleware(M.ConvertToInt)
      end

      field :starred_users, list_of(:user) do
        arg(:filter, :members_filter)

        middleware(M.PageSizeProof)
        resolve(dataloader(CMS, :stars))
      end
    end
  end

  defmacro comments_fields do
    quote do
      field(:id, :id)
      field(:body, :string)
      field(:floor, :integer)
      field(:author, :user, resolve: dataloader(CMS, :author))

      field :reply_to, :comment do
        resolve(dataloader(CMS, :reply_to))
      end

      field :likes, list_of(:user) do
        arg(:filter, :members_filter)

        middleware(M.PageSizeProof)
        resolve(dataloader(CMS, :likes))
      end

      field :likes_count, :integer do
        arg(:count, :count_type, default_value: :count)

        resolve(dataloader(CMS, :likes))
        middleware(M.ConvertToInt)
      end

      field :viewer_has_liked, :boolean do
        arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

        middleware(M.Authorize, :login)
        # put current user into dataloader's args
        middleware(M.PutCurrentUser)
        resolve(dataloader(CMS, :likes))
        middleware(M.ViewerDidConvert)
      end

      field :dislikes, list_of(:user) do
        arg(:filter, :members_filter)

        middleware(M.PageSizeProof)
        resolve(dataloader(CMS, :dislikes))
      end

      field :viewer_has_disliked, :boolean do
        arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

        middleware(M.Authorize, :login)
        # put current user into dataloader's args
        middleware(M.PutCurrentUser)
        resolve(dataloader(CMS, :dislikes))
        middleware(M.ViewerDidConvert)
      end

      field :dislikes_count, :integer do
        arg(:count, :count_type, default_value: :count)

        resolve(dataloader(CMS, :dislikes))
        middleware(M.ConvertToInt)
      end

      field :replies, list_of(:comment) do
        arg(:filter, :members_filter)

        middleware(M.ForceLoader)
        middleware(M.PageSizeProof)
        resolve(dataloader(CMS, :replies))
      end

      field :replies_count, :integer do
        arg(:count, :count_type, default_value: :count)

        resolve(dataloader(CMS, :replies))
        middleware(M.ConvertToInt)
      end

      timestamp_fields()
    end
  end

  defmacro comments_counter_fields(thread) do
    quote do
      # @dec "total comments of the post"
      field :comments_count, :integer do
        arg(:count, :count_type, default_value: :count)

        resolve(dataloader(CMS, :comments))
        middleware(M.ConvertToInt)
      end

      # @desc "unique participator list of a the comments"
      field :comments_participators, list_of(:user) do
        arg(:filter, :members_filter)
        arg(:unique, :unique_type, default_value: true)

        # middleware(M.ForceLoader)
        middleware(M.PageSizeProof)
        resolve(dataloader(CMS, :comments))
        middleware(M.CutParticipators)
      end

      field(:paged_comments_participators, :paged_users) do
        arg(
          :thread,
          unquote(String.to_atom("#{to_string(thread)}_thread")),
          default_value: unquote(thread)
        )

        resolve(&R.CMS.paged_comments_participators/3)
      end
    end
  end
end
