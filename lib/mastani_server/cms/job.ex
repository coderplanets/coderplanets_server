defmodule MastaniServer.CMS.Job do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias MastaniServer.CMS.{
    Author,
    Community,
    JobComment,
    JobFavorite,
    JobStar,
    JobViewer,
    JobCommunityFlag,
    Tag
  }

  @required_fields ~w(title company company_logo location body digest length)a
  @optional_fields ~w(link_addr link_source min_education)a

  @type t :: %Job{}
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
    field(:max_salary, :integer, default: 10_000_000)

    field(:min_experience, :integer, default: 1)
    field(:max_experience, :integer, default: 3)

    # college - bachelor - master - doctor
    field(:min_education, :string)

    field(:digest, :string)
    field(:length, :integer)

    has_many(:community_flags, {"jobs_communities_flags", JobCommunityFlag})

    # NOTE: this one is tricky, pin is dynamic changed when return by func: add_pin_contents_ifneed
    field(:pin, :boolean, default_value: false, virtual: true)
    field(:trash, :boolean, default_value: false, virtual: true)

    has_many(:comments, {"jobs_comments", JobComment})
    has_many(:favorites, {"jobs_favorites", JobFavorite})
    has_many(:stars, {"jobs_stars", JobStar})
    has_many(:viewers, {"jobs_viewers", JobViewer})

    many_to_many(
      :tags,
      Tag,
      join_through: "jobs_tags",
      join_keys: [job_id: :id, tag_id: :id],
      # :delete_all will only remove data from the join source
      on_delete: :delete_all,
      on_replace: :delete
    )

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
