defmodule GroupherServerWeb.Schema.Helper.Fields do
  @moduledoc """
  common fields
  """
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS

  @page_size get_config(:general, :page_size)
  @supported_emotions get_config(:article, :emotions)
  @supported_comment_emotions get_config(:article, :comment_emotions)

  @article_threads get_config(:article, :threads)

  defmacro timestamp_fields(:article) do
    quote do
      field(:inserted_at, :datetime)
      field(:updated_at, :datetime)
      field(:active_at, :datetime)
    end
  end

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

  defmacro article_filter_fields do
    quote do
      field(:when, :when_enum)
      field(:length, :length_enum)
      field(:article_tag, :string)
      field(:article_tags, list_of(:string))
      field(:community, :string)
    end
  end

  defmacro social_fields do
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

  alias GroupherServer.CMS
  alias GroupherServerWeb.Middleware, as: M
  alias GroupherServerWeb.Resolvers, as: R

  defmacro threads_count_fields() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        field(unquote(:"#{thread}s_count"), :integer)
      end
    end)
  end

  defmacro viewer_has_state_fields do
    quote do
      field(:viewer_has_collected, :boolean)
      field(:viewer_has_upvoted, :boolean)
      field(:viewer_has_viewed, :boolean)
      field(:viewer_has_reported, :boolean)
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

  defmacro article_comments_fields do
    quote do
      field(:article_comments_participators, list_of(:user))
      field(:article_comments_participators_count, :integer)
      field(:article_comments_count, :integer)
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

  @doc """
  general emotion enum for articles
  #NOTE: xxx_user_logins field is not support for gq-endpoint
  """
  defmacro emotion_enum() do
    @supported_emotions
    |> Enum.map(fn emotion ->
      quote do
        value(unquote(:"#{emotion}"))
      end
    end)
  end

  @doc """
  general emotion enum for comments
  #NOTE: xxx_user_logins field is not support for gq-endpoint
  """
  defmacro comment_emotion_enum() do
    @supported_comment_emotions
    |> Enum.map(fn emotion ->
      quote do
        value(unquote(:"#{emotion}"))
      end
    end)
  end

  @doc """
  general emotions for articles
  #NOTE: xxx_user_logins field is not support for gq-endpoint
  """
  defmacro emotion_fields() do
    @supported_emotions
    |> Enum.map(fn emotion ->
      quote do
        field(unquote(:"#{emotion}_count"), :integer)
        field(unquote(:"viewer_has_#{emotion}ed"), :boolean)
        field(unquote(:"latest_#{emotion}_users"), list_of(:simple_user))
      end
    end)
  end

  @doc """
  general emotions for comments
  #NOTE: xxx_user_logins field is not support for gq-endpoint
  """
  defmacro comment_emotion_fields() do
    @supported_comment_emotions
    |> Enum.map(fn emotion ->
      quote do
        field(unquote(:"#{emotion}_count"), :integer)
        field(unquote(:"viewer_has_#{emotion}ed"), :boolean)
        field(unquote(:"latest_#{emotion}_users"), list_of(:simple_user))
      end
    end)
  end

  @doc """
  general collect folder meta info
  """
  defmacro collect_folder_meta_fields() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        field(unquote(:"has_#{thread}"), :boolean)
        field(unquote(:"#{thread}_count"), :integer)
      end
    end)
  end
end
