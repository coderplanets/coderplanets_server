defmodule MastaniServer.CMS.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.{Post, Author, Comment}
  alias MastaniServer.Accounts

  schema "cms_posts" do
    field(:body, :string)
    field(:isRefined, :boolean, default: false)
    field(:isSticky, :boolean, default: false)
    field(:title, :string)
    field(:viewerCanCollect, :boolean, default: false)
    field(:viewerCanStar, :boolean, default: false)
    field(:viewerCanWatch, :boolean, default: false)
    field(:viewsCount, :integer)
    belongs_to(:author, Author)

    many_to_many(
      :starredUsers,
      Accounts.User,
      join_through: "users_posts_stars",
      on_delete: :delete_all
    )

    many_to_many(:comments, Comment, join_through: "cms_posts_comments")

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
