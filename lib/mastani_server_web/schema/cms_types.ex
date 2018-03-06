defmodule MastaniServerWeb.Schema.CMS.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  import Absinthe.Resolution.Helpers
  alias MastaniServer.{CMS, Accounts}
  alias MastaniServerWeb.{Resolvers, Schema}

  import_types(Schema.CMS.Misc)

  object :comment do
    field(:id, non_null(:id))
    field(:body, non_null(:string))
    field(:author, non_null(:user))
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :post do
    interface(:article)
    field(:id, :id)
    field(:title, :string)
    field(:digest, :string)
    field(:length, :integer)
    field(:link_addr, :string)
    field(:body, :string)
    field(:views, :integer)
    field(:tags, list_of(:tag), resolve: assoc(:tags))
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)

    # field :author_not_use_dataloader, :user do
      # resolve(&Resolvers.CMS.load_author/3)
    # end

    field :author, :user, resolve: dataloader(CMS, :author)

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

    field :viewer_has_favorited, :boolean do
      arg(:type, :post_type, default_value: :post)
      arg(:action, :favorite_action, default_value: :favorite)

      resolve(&Resolvers.CMS.viewer_has_reacted/3)
    end

    field :viewer_has_starred, :boolean do
      arg(:type, :post_type, default_value: :post)
      arg(:action, :star_action, default_value: :star)

      resolve(&Resolvers.CMS.viewer_has_reacted/3)
    end

    field :favorited_users, list_of(:user) do
      # TODO: tmp
      arg(:filter, :article_filter)
      arg(:type, :post_type, default_value: :post)
      arg(:action, :favorite_action, default_value: :favorite)
      resolve(&Resolvers.CMS.inline_reaction_users/3)
    end

    field :favorited_count, :integer do
      arg(:type, :post_type, default_value: :post)
      arg(:action, :favorite_action, default_value: :favorite)
      resolve(&Resolvers.CMS.inline_reaction_users_count/3)
    end

    field :starred_count, :integer do
      arg(:type, :post_type, default_value: :post)
      arg(:action, :star_action, default_value: :star)
      resolve(&Resolvers.CMS.inline_reaction_users_count/3)
    end

    field :starred_users, list_of(:user) do
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

  object :community do
    field(:title, :string)
    field(:desc, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :tag do
    field(:title, :string)
    field(:color, :string)
    field(:part, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
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
