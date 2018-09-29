defmodule MastaniServerWeb.Schema.CMS.Misc do
  use Absinthe.Schema.Notation

  import MastaniServerWeb.Schema.Utils.Helper

  alias MastaniServer.CMS

  @default_inner_page_size 5

  enum(:post_thread, do: value(:post))
  enum(:job_thread, do: value(:job))
  enum(:video_thread, do: value(:video))
  enum(:repo_thread, do: value(:repo))

  enum(:community_type, do: value(:community))
  enum(:comment_replies_type, do: value(:comment_replies_type))

  enum(:count_type, do: value(:count))
  enum(:viewer_did_type, do: value(:viewer_did))
  enum(:favorite_action, do: value(:favorite))

  enum(:cms_comment, do: value(:post_comment))
  enum(:star_action, do: value(:star))
  enum(:comment_action, do: value(:comment))

  enum :unique_type do
    value(true)
    value(false)
  end

  enum :cms_action do
    value(:favorite)
    value(:star)
    value(:watch)
  end

  enum :cms_thread do
    value(:post)
    value(:job)
    value(:user)
    value(:video)
    value(:repo)
    value(:wiki)
  end

  enum :order_enum do
    value(:asc)
    value(:desc)
  end

  enum :when_enum do
    value(:today)
    value(:this_week)
    value(:this_month)
    value(:this_year)
  end

  enum :comment_sort_enum do
    value(:asc_inserted)
    value(:desc_inserted)
    value(:most_likes)
    value(:most_dislikes)
  end

  enum :thread_sort_enum do
    value(:asc_index)
    value(:desc_index)
    value(:asc_inserted)
    value(:desc_inserted)
  end

  enum :sort_enum do
    value(:most_views)
    value(:most_updated)
    value(:most_favorites)
    value(:most_stars)
    value(:most_watched)
    value(:most_comments)
    value(:least_views)
    value(:least_updated)
    value(:least_favorites)
    value(:least_stars)
    value(:least_watched)
    value(:least_comments)
    value(:recent_updated)
  end

  enum :rainbow_color_enum do
    value(:red)
    value(:orange)
    value(:yellow)
    value(:green)
    value(:cyan)
    value(:blue)
    value(:purple)
  end

  @desc "inline members-like filter for dataloader usage"
  input_object :members_filter do
    field(:first, :integer, default_value: @default_inner_page_size)
  end

  input_object :comments_filter do
    pagination_args()
    field(:sort, :comment_sort_enum, default_value: :asc_inserted)
  end

  input_object :communities_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    pagination_args()
    field(:sort, :sort_enum)
    field(:category, :string)
  end

  input_object :threads_filter do
    pagination_args()
    field(:sort, :thread_sort_enum)
  end

  input_object :paged_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    pagination_args()
    field(:sort, :sort_enum)
  end

  @desc "article_filter doc"
  input_object :article_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    field(:first, :integer)

    @desc "Matching a tag"
    field(:tag, :string, default_value: :all)
    # field(:sort, :sort_input)
    field(:when, :when_enum)
    field(:sort, :sort_enum)
    # @desc "Matching a tag"
    # @desc "Added to the menu after this date"
    # field(:added_after, :datetime)
  end

  @desc "article_filter doc"
  input_object :paged_article_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    pagination_args()

    field(:when, :when_enum)
    field(:sort, :sort_enum)
    field(:tag, :string, default_value: :all)
    field(:community, :string)

    # @desc "Matching a name"
    # field(:order, :order_enum, default_value: :desc)

    # @desc "Matching a tag"
    # field(:tag, :string, default_value: :all)
  end

  @doc """
  cms github repo contribotor
  """
  input_object :repo_contributor_input do
    field(:avatar, :string)
    field(:html_url, :string)
    field(:nickname, :string)
  end

  @doc """
  cms github repo lang
  """
  input_object :repo_lang_input do
    field(:name, :string)
    field(:color, :string)
  end

  @doc """
  only used for reaction result, like: favorite/star/watch ...
  """
  interface :article do
    field(:id, :id)
    field(:title, :string)

    resolve_type(fn
      %CMS.Post{}, _ -> :post
      _, _ -> nil
    end)
  end

  # @desc """
  # The `DateTime` scalar type represents a date and time in the UTC
  # timezone. The DateTime appears in a JSON response as an ISO8601 formatted
  # string, including UTC timezone ("Z"). The parsed date and time string will
  # be converted to UTC and any UTC offset other than 0 will be rejected.
  # """
  # scalar :datetime, name: "DateTime" do
  # serialize &DateTime.to_iso8601/1
  # parse &parse_datetime/1
  # end

  # @spec parse_datetime(Absinthe.Blueprint.Input.String.t) :: {:ok, DateTime.t} | :error
  # @spec parse_datetime(Absinthe.Blueprint.Input.Null.t) :: {:ok, nil}
  # defp parse_datetime(%Absinthe.Blueprint.Input.String{value: value}) do
  # case DateTime.from_iso8601(value) do
  # {:ok, datetime, 0} -> {:ok, datetime}
  # {:ok, _datetime, _offset} -> :error
  # _error -> :error
  # end
  # end
  # defp parse_datetime(%Absinthe.Blueprint.Input.Null{}) do
  # {:ok, nil}
  # end
  # defp parse_datetime(_) do
  # :error
  # end
end
