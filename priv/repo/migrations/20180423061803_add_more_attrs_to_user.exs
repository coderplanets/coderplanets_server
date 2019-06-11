defmodule GroupherServer.Repo.Migrations.AddMoreAttrsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:location, :string)
      add(:email, :string)
      add(:company, :string)
      add(:education, :string)
      add(:qq, :string)
      add(:weichat, :string)
      add(:weibo, :string)
    end
  end
end
