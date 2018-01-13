defmodule MastaniServer.CMS.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Post, Author, PostComment, PostFavorite, PostStar, PostTag}
  # alias MastaniServer.Accounts

  schema "cms_posts" do
    field(:body, :string)
    field(:title, :string)
    field(:views, :integer, default: 0)
    belongs_to(:author, Author)

    # many_to_many(:comments, Comment, join_through: "posts_comments")
    has_many(:comments, {"posts_comments", PostComment})
    has_many(:favorites, {"posts_favorites", PostFavorite})
    has_many(:stars, {"posts_stars", PostStar})
    # The keys are inflected from the schema names!
    # see https://hexdocs.pm/ecto/Ecto.Schema.html
    many_to_many(
      :tags,
      PostTag,
      join_through: "posts_join_tags",
      join_keys: [post_id: :id, tag_id: :id]
    )

    # has_many(:watches, {"post_watches", PostWatch})

    timestamps()
  end

  # create table(:cms_posts_comments) do
  # add(:comment_id, references(:cms_comments))
  # add(:post_id, references(:cms_posts))
  # end
  # end

  # create(index(:cms_posts_comments, [:post_id]))

  # create(unique_index(:cms_posts_comments, [:user_id]))

  # alter table(:cms_posts) do
  #   add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)
  # end
  # create(index(:cms_posts, [:author_id]))

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, [
      :title,
      :body
      # :viewsCount
      # :isRefined,
      # :isSticky,
      # :viewerCanStar,
      # :viewerCanWatch,
      # :viewerCanCollect
    ])
    |> validate_required([
      :title,
      :body
    ])
  end
end
