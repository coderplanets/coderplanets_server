defmodule GroupherServer.Accounts.User do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema

  # import GroupherServerWeb.Schema.Utils.Helper
  import Ecto.Changeset

  alias GroupherServer.Accounts.{
    Achievement,
    Customization,
    EducationBackground,
    FavoriteCategory,
    GithubUser,
    Purchase,
    UserFollower,
    UserFollowing,
    WorkBackground,
    Social
  }

  alias GroupherServer.CMS

  @required_fields ~w(nickname avatar)a
  @optional_fields ~w(login nickname bio remote_ip sex location email)a

  @type t :: %User{}
  schema "users" do
    field(:login, :string)
    field(:nickname, :string)
    field(:avatar, :string)
    field(:sex, :string)
    field(:bio, :string)
    field(:email, :string)
    field(:location, :string)
    field(:from_github, :boolean)
    field(:geo_city, :string)
    field(:remote_ip, :string)

    field(:views, :integer, default: 0)

    embeds_many(:education_backgrounds, EducationBackground)
    embeds_many(:work_backgrounds, WorkBackground)

    has_one(:social, Social)

    has_one(:achievement, Achievement)
    has_one(:github_profile, GithubUser)
    has_one(:cms_passport, CMS.Passport)

    has_many(:followers, {"users_followers", UserFollower})
    has_many(:followings, {"users_followings", UserFollowing})

    has_many(:subscribed_communities, {"communities_subscribers", CMS.CommunitySubscriber})

    # stared contents
    has_many(:stared_posts, {"posts_stars", CMS.PostStar})
    has_many(:stared_jobs, {"jobs_stars", CMS.JobStar})
    has_many(:stared_videos, {"videos_stars", CMS.VideoStar})

    # favorited contents
    has_many(:favorited_posts, {"posts_favorites", CMS.PostFavorite})
    has_many(:favorited_jobs, {"jobs_favorites", CMS.JobFavorite})
    has_many(:favorited_videos, {"videos_favorites", CMS.VideoFavorite})
    has_many(:favorited_repos, {"repos_favorites", CMS.RepoFavorite})

    has_many(:favorite_categories, {"favorite_categories", FavoriteCategory})

    field(:sponsor_member, :boolean)
    field(:paid_member, :boolean)
    field(:platinum_member, :boolean)

    has_one(:customization, Customization)
    has_one(:purchase, Purchase)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> update_changeset(attrs)
    |> validate_required(@required_fields)

    # |> unique_constraint(:username)
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> cast_embed(:education_backgrounds, with: &EducationBackground.changeset/2)
    |> cast_embed(:work_backgrounds, with: &WorkBackground.changeset/2)
    |> validate_length(:nickname, min: 3, max: 30)
    |> validate_length(:bio, min: 3, max: 100)
    |> validate_inclusion(:sex, ["dude", "girl"])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:location, min: 2, max: 30)

    # |> validate_length(:qq, min: 8, max: 15)
    # |> validate_length(:weichat, min: 3, max: 30)
    # |> validate_length(:weibo, min: 3, max: 30)
  end
end
