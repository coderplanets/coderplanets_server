defmodule MastaniServer.Accounts.User do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias MastaniServer.Accounts.{
    Customization,
    GithubUser,
    Purchase,
    UserBill,
    UserFollower,
    UserFollowing
  }

  alias MastaniServer.CMS

  @type t :: %User{}

  schema "users" do
    field(:nickname, :string)
    field(:avatar, :string)
    field(:sex, :string)
    field(:bio, :string)
    field(:email, :string)
    field(:location, :string)
    field(:education, :string)
    field(:company, :string)
    field(:qq, :string)
    field(:weibo, :string)
    field(:weichat, :string)
    field(:from_github, :boolean)
    has_one(:github_profile, GithubUser)
    has_one(:cms_passport, CMS.Passport)

    has_many(:followers, {"users_followers", UserFollower})
    has_many(:followings, {"users_followings", UserFollowing})

    has_many(:subscribed_communities, {"communities_subscribers", CMS.CommunitySubscriber})
    has_many(:favorited_posts, {"posts_favorites", CMS.PostFavorite})
    has_many(:favorited_jobs, {"jobs_favorites", CMS.JobFavorite})

    field(:sponsor_member, :boolean)
    field(:paid_member, :boolean)
    field(:platinum_member, :boolean)

    has_many(:bills, {"users_bills", UserBill})
    has_one(:customization, Customization)
    has_one(:purchase, Purchase)

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(nickname avatar)a
  @optional_fields ~w(nickname bio avatar sex location email company education qq weichat weibo)a

  @doc false
  def changeset(%User{} = user, attrs) do
    # |> cast(attrs, [:username, :nickname, :bio, :company])
    # |> validate_required([:username])
    # |> cast(attrs, @required_fields, @optional_fields)
    user
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:nickname, min: 3, max: 30)
    |> validate_length(:bio, min: 3, max: 100)
    |> validate_inclusion(:sex, ["dude", "girl"])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:location, min: 2, max: 30)
    |> validate_length(:company, min: 3, max: 30)
    |> validate_length(:qq, min: 8, max: 15)
    |> validate_length(:weichat, min: 3, max: 30)
    |> validate_length(:weibo, min: 3, max: 30)

    # |> unique_constraint(:username)
  end
end
