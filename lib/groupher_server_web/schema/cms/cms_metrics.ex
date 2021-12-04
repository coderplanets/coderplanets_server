defmodule GroupherServerWeb.Schema.CMS.Metrics do
  @moduledoc """
  common metrics in queries
  """
  use Absinthe.Schema.Notation
  import GroupherServerWeb.Schema.Helper.Fields

  import Helper.Utils, only: [module_to_atom: 1]

  @default_inner_page_size 5

  @doc """
  only used for reaction result, like: upvote/collect/watch ...
  """
  interface :article do
    # article 所包含的共同字段
    field(:id, :id)
    field(:title, :string)
    field(:views, :integer)
    field(:upvotes_count, :integer)
    field(:meta, :article_meta)
    field(:pending, :integer)

    # 这里只是遵循 absinthe 的规范，并不是指返回以下的字段
    resolve_type(fn parent_module, _ -> module_to_atom(parent_module) end)
  end

  article_thread_enums()

  @desc "emotion options of article"
  enum(:article_emotion, do: emotion_values())

  @desc "emotion options of comment"
  enum(:comment_emotion, do: emotion_values(:comment))

  enum :thread do
    article_values()
    value(:user)
    value(:wiki)
    value(:cheatsheet)
    # home community
    value(:tech)
    value(:city)
    value(:share)
  end

  enum :content do
    article_values()
    value(:comment)
  end

  enum :when_enum do
    value(:today)
    value(:this_week)
    value(:this_month)
    value(:this_year)
  end

  enum :inserted_sort_enum do
    value(:asc_inserted)
    value(:desc_inserted)
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
    value(:most_upvotes)
    value(:most_stars)
    value(:most_comments)
    value(:least_views)
    value(:least_updated)
    value(:least_upvotes)
    value(:least_stars)
    value(:least_watched)
    value(:least_comments)
    value(:recent_updated)
  end

  enum :repo_sort_enum do
    value(:most_github_star)
    value(:most_github_fork)
    value(:most_github_watch)
    value(:most_github_pr)
    value(:most_github_issue)
    value(:most_views)
    value(:most_comments)
    value(:recent_updated)
    value(:most_upvotes)
  end

  enum :length_enum do
    value(:most_words)
    value(:least_words)
  end

  enum :rainbow_color do
    value(:red)
    value(:orange)
    value(:yellow)
    value(:green)
    value(:cyan)
    value(:blue)
    value(:purple)
    value(:dodgerblue)
    value(:yellowgreen)
    value(:brown)
    value(:grey)
  end

  @desc "the filter mode for list comments"
  enum :comments_mode do
    value(:replies)
    value(:timeline)
  end

  @desc "inline members-like filter for dataloader usage"
  input_object :members_filter do
    field(:first, :integer, default_value: @default_inner_page_size)
  end

  input_object :comments_filter do
    pagination_args()
    field(:sort, :inserted_sort_enum, default_value: :asc_inserted)
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

  input_object :article_tags_filter do
    field(:community_id, :id)
    field(:community_raw, :string)
    field(:thread, :thread)
    pagination_args()
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
    field(:article_tag, :string)
    # field(:sort, :sort_input)
    field(:when, :when_enum)
    field(:sort, :sort_enum)
    # @desc "Matching a tag"
    # @desc "Added to the menu after this date"
    # field(:added_after, :datetime)
  end

  # @desc "article_filter doc"
  # input_object :paged_article_filter do
  #   @desc "limit of records (default 20), if first > 30, only return 30 at most"
  #   pagination_args()
  #   article_filter_fields()
  #   field(:sort, :sort_enum)
  # end

  @desc "posts_filter doc"
  input_object :paged_posts_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    pagination_args()
    article_filter_fields()
    field(:sort, :sort_enum)
  end

  @desc "job_filter doc"
  input_object :paged_jobs_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    pagination_args()
    article_filter_fields()
    field(:sort, :sort_enum)
  end

  @desc "blog_filter doc"
  input_object :paged_blogs_filter do
    pagination_args()
    article_filter_fields()
    field(:sort, :sort_enum)
  end

  @desc "works_filter doc"
  input_object :paged_works_filter do
    pagination_args()
    article_filter_fields()
    field(:sort, :sort_enum)
  end

  @desc "radar_filter doc"
  input_object :paged_radars_filter do
    pagination_args()
    article_filter_fields()
    field(:sort, :sort_enum)
  end

  @desc "guide_filter doc"
  input_object :paged_guides_filter do
    pagination_args()
    article_filter_fields()
    field(:sort, :sort_enum)
  end

  @desc "meetup_filter doc"
  input_object :paged_meetups_filter do
    pagination_args()
    article_filter_fields()
    field(:sort, :sort_enum)
  end

  @desc "drink_filter doc"
  input_object :paged_drinks_filter do
    pagination_args()
    article_filter_fields()
    field(:sort, :sort_enum)
  end

  @desc "article_filter doc"
  input_object :paged_repos_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    pagination_args()
    article_filter_fields()

    field(:sort, :repo_sort_enum)
  end

  @desc "common filter for upvoted articles"
  input_object :upvoted_articles_filter do
    field(:thread, :thread)
    pagination_args()
  end

  @desc "common filter for collect folders"
  input_object :collect_folders_filter do
    field(:thread, :thread)
    pagination_args()
  end

  @desc "common filter for collect articles"
  input_object :collected_articles_filter do
    field(:thread, :thread)
    pagination_args()
  end

  @desc """
  cms github repo contribotor
  """
  input_object :repo_contributor_input do
    field(:avatar, :string)
    field(:html_url, :string)
    field(:nickname, :string)
  end

  @desc """
  cms github repo contribotor, detail version
  """
  input_object :github_contributor_input do
    field(:github_id, non_null(:string))
    field(:avatar, non_null(:string))
    field(:html_url, non_null(:string))
    field(:nickname, non_null(:string))
    field(:bio, :string)
    field(:location, :string)
    field(:company, :string)
  end

  @desc """
  cms github repo lang
  """
  input_object :repo_lang_input do
    field(:name, :string)
    field(:color, :string)
  end

  enum :report_content_type do
    article_values()
    value(:account)
    value(:comment)
    # value(:community)
  end

  @desc """
  abuse report filter
  """
  input_object :report_filter do
    field(:content_type, :report_content_type)
    field(:content_id, :id)
    pagination_args()
  end

  # works-spec
  enum :profit_mode do
    value(:ad)
    value(:freemium)
    value(:free)
    value(:product)
    value(:others)
  end

  enum :working_mode do
    value(:fulltime)
    value(:side_project)
  end

  object :city do
    field(:title, :string)
    field(:logo, :string)
    field(:desc, :string)
    field(:raw, :string)
  end

  object :techstack do
    field(:title, :string)
    field(:logo, :string)
    field(:desc, :string)
    field(:raw, :string)

    field(:home_link, :string)
    field(:community_link, :string)
    field(:category, :string)
  end

  object :social do
    field(:platform, :string)
    field(:link, :string)
  end

  object :app_store do
    field(:platform, :string)
    field(:link, :string)
  end

  input_object :social_info do
    field(:platform, :string)
    field(:link, :string)
  end

  input_object :app_store_info do
    field(:platform, :string)
    field(:link, :string)
  end
end
