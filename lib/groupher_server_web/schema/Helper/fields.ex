defmodule GroupherServerWeb.Schema.Helper.Fields do
  @moduledoc """
  general fields used in GraphQL schema definition
  """
  import Helper.Utils, only: [get_config: 2, plural: 1]
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  alias GroupherServer.CMS

  @page_size get_config(:general, :page_size)

  @emotions get_config(:article, :emotions)
  @comment_emotions get_config(:article, :comment_emotions)
  @article_threads get_config(:article, :threads)

  @doc "general article fields for grqphql resolve fields"
  defmacro general_article_fields() do
    quote do
      field(:id, :id)
      field(:title, :string)
      field(:document, :thread_document, resolve: dataloader(CMS, :document))
      field(:digest, :string)
      field(:views, :integer)
      field(:is_pinned, :boolean)
      field(:mark_delete, :boolean)

      field(:article_tags, list_of(:article_tag), resolve: dataloader(CMS, :article_tags))
      field(:author, :user, resolve: dataloader(CMS, :author))
      field(:original_community, :community, resolve: dataloader(CMS, :original_community))
      field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

      field(:meta, :article_meta)
      field(:upvotes_count, :integer)
      field(:collects_count, :integer)
      field(:emotions, :article_emotions)

      field(:viewer_has_collected, :boolean)
      field(:viewer_has_upvoted, :boolean)
      field(:viewer_has_viewed, :boolean)
      field(:viewer_has_reported, :boolean)

      field(:is_archived, :boolean)
      field(:archived_at, :datetime)

      field(:copy_right, :string)
      field(:link_addr, :string)

      field(:pending, :integer)
    end
  end

  @doc """
  generate thread enum based on @article_threads

  e.g:

  enum :post_thread, do: value(:post)
  enum :job_thread, do: value(:job)
  # ..
  """
  defmacro article_thread_enums do
    @article_threads
    |> Enum.map(
      &quote do
        enum(unquote(:"#{&1}_thread"), do: value(unquote(&1)))
      end
    )
  end

  @doc """
  generate thread value based on @article_threads

  e.g:

  value(:post)
  value(:job)
  # ...
  """
  defmacro article_values do
    @article_threads
    |> Enum.map(
      &quote do
        value(unquote(&1))
      end
    )
  end

  @doc """
  general emotion enum for articles
  #NOTE: xxx_user_logins field is not support for gq-endpoint
  """
  defmacro emotion_values(metric \\ :article) do
    emotions =
      case metric do
        :comment -> @comment_emotions
        _ -> @emotions
      end

    emotions
    |> Enum.map(
      &quote do
        value(unquote(:"#{&1}"))
      end
    )
  end

  @doc """
  general emotions for articles

  e.g:
  ------
  beer_count
  viewer_has_beered
  latest_bear_users
  """
  defmacro emotion_fields() do
    @emotions
    |> Enum.map(
      &quote do
        field(unquote(:"#{&1}_count"), :integer)
        field(unquote(:"viewer_has_#{&1}ed"), :boolean)
        field(unquote(:"latest_#{&1}_users"), list_of(:common_user))
      end
    )
  end

  defmacro emotion_fields(:comment) do
    @comment_emotions
    |> Enum.map(
      &quote do
        field(unquote(:"#{&1}_count"), :integer)
        field(unquote(:"viewer_has_#{&1}ed"), :boolean)
        field(unquote(:"latest_#{&1}_users"), list_of(:common_user))
      end
    )
  end

  @doc """
  general timestamp with active_at for article
  """
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

  defmacro comment_general_fields do
    quote do
      field(:id, :id)
      field(:body, :string)
      field(:body_html, :string)
      field(:author, :user, resolve: dataloader(CMS, :author))
      field(:is_pinned, :boolean)
      field(:floor, :integer)
      field(:upvotes_count, :integer)
      field(:is_article_author, :boolean)
      field(:emotions, :comment_emotions)
      field(:meta, :comment_meta)
      field(:replies_count, :integer)
      field(:thread, :string)
      field(:viewer_has_upvoted, :boolean)
      field(:reply_to, :comment, resolve: dataloader(CMS, :reply_to))
      field(:reply_to_id, :id)

      field(:is_deleted, :boolean)
      field(:is_archived, :boolean)
      field(:archived_at, :datetime)

      timestamp_fields()
    end
  end

  # see: https://github.com/absinthe-graphql/absinthe/issues/363
  defmacro pagination_args do
    quote do
      field(:page, :integer, default_value: 1)
      field(:size, :integer, default_value: unquote(@page_size))
    end
  end

  @doc """
  general pagination fields except entries
  """
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
      field(:article_tag, :string)
      field(:article_tags, list_of(:string))
      field(:community, :string)
    end
  end

  @doc """
  general social used for user profile
  """
  defmacro social_fields do
    quote do
      field(:github, :string)
      field(:company, :string)
      field(:blog, :string)
      field(:douban, :string)
      field(:twitter, :string)
      field(:zhihu, :string)
      field(:dribble, :string)
      field(:pinterest, :string)
      field(:huaban, :string)
    end
  end

  defmacro threads_count_fields() do
    @article_threads
    |> Enum.map(
      &quote do
        field(unquote(:"#{plural(&1)}_count"), :integer)
      end
    )
  end

  defmacro comments_fields do
    quote do
      field(:comments_participants, list_of(:user))
      field(:comments_participants_count, :integer)
      field(:comments_count, :integer)
    end
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
