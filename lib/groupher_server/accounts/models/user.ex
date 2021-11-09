defmodule GroupherServer.Accounts.Model.User do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  # import GroupherServerWeb.Schema.Helper.Fields
  import Ecto.Changeset

  alias GroupherServer.Accounts.Model.{
    Achievement,
    Embeds,
    Customization,
    EducationBackground,
    CollectFolder,
    GithubUser,
    Purchase,
    UserFollower,
    UserFollowing,
    WorkBackground,
    Social
  }

  alias GroupherServer.CMS.Model.{Passport, CommunitySubscriber}

  @required_fields ~w(nickname avatar)a
  @optional_fields ~w(login nickname bio shortbio remote_ip sex location email subscribed_communities_count)a

  @type t :: %User{}
  schema "users" do
    field(:login, :string)
    field(:nickname, :string)
    field(:avatar, :string)
    field(:sex, :string)
    field(:bio, :string)
    field(:shortbio, :string)
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
    has_one(:cms_passport, Passport)

    has_many(:followers, {"users_followers", UserFollower})
    has_many(:followings, {"users_followings", UserFollowing})

    has_many(:subscribed_communities, {"communities_subscribers", CommunitySubscriber})
    field(:subscribed_communities_count, :integer, default: 0)

    has_many(:collect_folder, {"collect_folders", CollectFolder})

    # field(:sponsor_member, :boolean)
    # field(:paid_member, :boolean)
    # field(:platinum_member, :boolean)

    field(:viewer_has_reported, :boolean, default: false, virtual: true)
    # 已关注
    field(:viewer_has_followed, :boolean, default: false, virtual: true)
    # Ta 关注了你
    field(:viewer_been_followed, :boolean, default: false, virtual: true)

    field(:followings_count, :integer, default: 0)
    field(:followers_count, :integer, default: 0)

    embeds_one(:meta, Embeds.UserMeta, on_replace: :update)
    embeds_one(:contributes, Embeds.UserContribute, on_replace: :update)
    embeds_one(:mailbox, Embeds.UserMailbox, on_replace: :update)

    has_one(:customization, Customization)
    has_one(:purchase, Purchase)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> update_changeset(attrs)
    |> cast_embed(:meta, required: false, with: &Embeds.UserMeta.changeset/2)
    |> validate_required(@required_fields)

    # |> unique_constraint(:username)
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> cast_embed(:education_backgrounds, with: &EducationBackground.changeset/2)
    |> cast_embed(:work_backgrounds, with: &WorkBackground.changeset/2)
    |> cast_embed(:meta, required: false, with: &Embeds.UserMeta.changeset/2)
    |> cast_embed(:mailbox, required: false, with: &Embeds.UserMailbox.changeset/2)
    |> validate_length(:nickname, min: 3, max: 30)
    |> validate_length(:bio, min: 3, max: 100)
    |> validate_inclusion(:sex, ["dude", "girl"])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:location, min: 2, max: 30)
  end
end
