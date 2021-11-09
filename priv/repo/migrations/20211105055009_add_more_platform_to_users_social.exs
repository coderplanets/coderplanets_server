defmodule GroupherServer.Repo.Migrations.AddMorePlatformToUsersSocial do
  use Ecto.Migration

  def change do
    alter table(:user_socials) do
      add(:company, :string)
      add(:blog, :string)
      remove(:facebook, :string)

      remove(:instagram, :string)

      remove(:qq, :string)
      remove(:weichat, :string)
      remove(:weibo, :string)
    end
  end
end
