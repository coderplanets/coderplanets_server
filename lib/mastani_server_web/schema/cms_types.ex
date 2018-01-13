defmodule MastaniServerWeb.Schema.CMS.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  alias MastaniServerWeb.Resolvers
  alias MastaniServer.CMS

  enum :post_type do
    value(:post)
  end

  enum :favorite_action do
    value(:favorite)
  end

  enum :star_action do
    value(:star)
  end

  enum :comment_action do
    value(:comment)
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

  object :comment do
    field(:id, non_null(:id))
    field(:body, non_null(:string))
    field(:author, non_null(:user))
  end

  @desc "article_filter doc"
  input_object :article_filter do
    @desc "limit of records (default 20), if first > 30, only return 30 at most"
    field(:first, :integer, default_value: 20)

    @desc "Matching a name"
    # field(:order, :order_enum, default_value: :desc)
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

    @desc "Matching a name"
    field(:order, :order_enum, default_value: :desc)

    @desc "Matching a tag"
    field(:tag, :string, default_value: :all)
  end

  @doc """
  only used for reaction result, like: favorite/star/watch ...
  """
  interface :article do
    field(:id, :id)
    field(:title, :string)

    resolve_type(fn
      %CMS.Post{}, _ -> :post
      _, _ -> :fuck
    end)
  end

  object :fuck do
    field(:id, :id)
  end

  object :tag do
    field(:title, :string)
  end

  object :post do
    interface(:article)
    field(:id, :id)
    field(:title, :string)
    field(:body, :string)
    field(:views, :integer)
    field(:tags, list_of(:tag), resolve: assoc(:tags))

    field :author, :user do
      resolve(&Resolvers.CMS.load_author/3)
    end

    # TODO: isViewerfavorited, commentsCount, favoritesCount, starsCount ...

    field :comments, list_of(:comment) do
      # arg(:type, :cms_part, default_value: :post)
      arg(:type, :post_type, default_value: :post)
      arg(:filter, :article_filter)
      arg(:action, :comment_action, default_value: :comment)
      resolve(&Resolvers.CMS.inline_reaction_users/3)
    end

    # field :tags, list_of(:tag) do
    # resolve(&Resolvers.CMS.load_tags/3)
    # end

    field :favorites, list_of(:user) do
      # TODO: tmp
      arg(:filter, :article_filter)
      arg(:type, :post_type, default_value: :post)
      arg(:action, :favorite_action, default_value: :favorite)
      resolve(&Resolvers.CMS.inline_reaction_users/3)
    end

    field :star_count, :integer do
      arg(:type, :post_type, default_value: :post)
      arg(:action, :star_action, default_value: :star)
      resolve(&Resolvers.CMS.inline_reaction_users_count/3)
    end

    field :stars, list_of(:user) do
      # TODO: tmp
      arg(:filter, :article_filter)
      arg(:type, :post_type, default_value: :post)
      arg(:action, :star_action, default_value: :star)
      resolve(&Resolvers.CMS.inline_reaction_users/3)
    end
  end

  object :paged_posts do
    field(:entries, non_null(list_of(non_null(:post))))
    field(:total_entries, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end

  object :tag do
    field(:title, :string)
  end

  # object :author do
  # field(:id, non_null(:id))
  # field(:role, :string)
  # field(:posts, list_of(:post), resolve: assoc(:posts))
  # end

  # object :comment do
  # field(:id, non_null(:id))
  # field(:body, :string)
  # end
end
