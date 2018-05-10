defmodule MastaniServerWeb.Schema.CMS.Misc do
  use Absinthe.Schema.Notation
  import Helper.Utils, only: [get_config: 2]

  alias MastaniServer.CMS

  @max_page_size get_config(:general, :page_size)
  @default_inner_page_size 5

  enum :community_part_enum do
    value(:post)
    value(:job)
    value(:video)
  end

  enum :comment_replies_type do
    value(:comment_replies_type)
  end

  enum :post_type do
    value(:post)
  end

  enum :community_type do
    value(:community)
  end

  enum :favorite_action do
    value(:favorite)
  end

  enum :count_type do
    value(:count)
  end

  enum :viewer_did_type do
    value(:viewer_did)
  end

  enum :star_action do
    value(:star)
  end

  enum :comment_action do
    value(:comment)
  end

  enum :unique_type do
    value(true)
    value(false)
  end

  enum :cms_action do
    value(:favorite)
    value(:star)
    value(:watch)
  end

  enum :cms_part do
    value(:post)
    value(:job)
    value(:meetup)
  end

  enum :cms_comment do
    value(:post_comment)
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
    field(:page, :integer, default_value: 1)
    field(:size, :integer, default_value: @max_page_size)
    field(:sort, :comment_sort_enum, default_value: :asc_inserted)
  end

  input_object :paged_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    field(:page, :integer, default_value: 1)
    field(:size, :integer, default_value: @max_page_size)
    field(:sort, :sort_enum)
  end

  @desc "article_filter doc"
  input_object :article_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    # field(:first, :integer, default_value: @max_page_size)
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
    field(:page, :integer, default_value: 1)
    field(:size, :integer, default_value: 20)

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
end
