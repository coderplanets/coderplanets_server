defmodule GroupherServer.Accounts.Model.Social do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.Accounts.User

  @required_fields ~w(user_id)a
  @optional_fields ~w(github twitter facebook zhihu dribble huaban douban pinterest instagram qq weichat weibo)a

  @type t :: %Social{}
  schema "user_socials" do
    belongs_to(:user, User)

    field(:github, :string)
    field(:twitter, :string)
    field(:facebook, :string)
    field(:zhihu, :string)
    field(:dribble, :string)
    field(:huaban, :string)
    field(:douban, :string)

    field(:pinterest, :string)
    field(:instagram, :string)

    field(:qq, :string)
    field(:weichat, :string)
    field(:weibo, :string)

    # timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Social{} = social, attrs) do
    social
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user, name: :user_socials_user_id_index)
  end

  @doc false
  def update_changeset(%Social{} = social, attrs) do
    social
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user, name: :user_socials_user_id_index)
  end
end
