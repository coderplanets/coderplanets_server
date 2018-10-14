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

  # fields for: favorite count, users, viewer_did_favorite..
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
end
