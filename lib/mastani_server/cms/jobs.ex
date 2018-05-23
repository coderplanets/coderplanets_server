defmodule MastaniServer.CMS.Job do
  use Ecto.Schema
  import Ecto.Changeset
  # alias MastaniServer.CMS.{Job, Author, PostComment, PostFavorite, PostStar, Tag, Community}
  alias MastaniServer.CMS.{Job, Author, Community}
  # alias MastaniServer.Accounts

  @required_fields ~w(title company company_logo location body digest length)a
  @optional_fields ~w(link_addr link_source)a

  schema "cms_jobs" do
    field(:title, :string)
    field(:company, :string)
    field(:bonus, :string)
    field(:company_logo, :string)
    field(:location, :string)
    field(:desc, :string)
    field(:body, :string)
    belongs_to(:author, Author)
    field(:views, :integer, default: 0)
    field(:link_addr, :string)
    field(:link_source, :string)

    field(:min_salary, :integer, default: 0)
    field(:max_salary, :integer, default: 10000000)

    field(:min_experience, :integer, default: 1)
    field(:max_experience, :integer, default: 3)

    # college - bachelor - master - doctor
    field(:min_education, :string, default: 'college')

    field(:digest, :string)
    field(:length, :integer)

    # has_many(:comments, {"posts_comments", PostComment})
    # has_many(:favorites, {"posts_favorites", PostFavorite})
    # has_many(:stars, {"posts_stars", PostStar})

    # many_to_many(
      # :tags,
      # Tag,
      # join_through: "posts_tags",
      # join_keys: [post_id: :id, tag_id: :id],
      # on_replace: :delete
    # )

    many_to_many(
      :communities,
      Community,
      join_through: "communities_jobs",
      on_replace: :delete
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Job{} = job, attrs) do
    job
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end
end
