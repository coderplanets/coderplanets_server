defmodule GroupherServer.Repo.Migrations.AddUserSocials do
  use Ecto.Migration

  def change do
    create table(:user_socials) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      add(:github, :string)
      add(:twitter, :string)
      add(:facebook, :string)
      add(:zhihu, :string)
      add(:dribble, :string)
      add(:huaban, :string)
      add(:douban, :string)

      add(:pinterest, :string)
      add(:instagram, :string)

      add(:qq, :string)
      add(:weichat, :string)
      add(:weibo, :string)
    end

    create(unique_index(:user_socials, [:user_id]))
  end
end
