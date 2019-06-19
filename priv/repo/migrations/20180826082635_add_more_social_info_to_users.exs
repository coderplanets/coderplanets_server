defmodule GroupherServer.Repo.Migrations.AddMoreSocialInfoToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:github, :string)
      add(:twitter, :string)
      add(:facebook, :string)
      add(:zhihu, :string)
      add(:dribble, :string)
      add(:huaban, :string)
      add(:douban, :string)
    end
  end
end
