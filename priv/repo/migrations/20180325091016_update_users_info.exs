defmodule GroupherServer.Repo.Migrations.UpdateUsersInfo do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:company)
      remove(:username)
      add(:avatar, :string)
      add(:sex, :string)
      add(:from_github, :boolean, default: false)
      add(:from_weixin, :boolean, default: false)
    end
  end
end
