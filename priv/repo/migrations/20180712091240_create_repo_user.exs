defmodule GroupherServer.Repo.Migrations.CreateRepoUser do
  use Ecto.Migration

  def change do
    create table(:cms_repo_users) do
      add(:nickname, :string)
      add(:bio, :string)
      add(:avatar, :string)
      add(:link, :string)
    end
  end
end
