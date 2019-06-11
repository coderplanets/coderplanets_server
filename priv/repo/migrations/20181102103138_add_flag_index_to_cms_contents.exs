defmodule GroupherServer.Repo.Migrations.AddFlagIndexToCmsContents do
  use Ecto.Migration

  def change do
    create(index(:posts_communities_flags, [:trash]))
    create(index(:jobs_communities_flags, [:trash]))
    create(index(:repos_communities_flags, [:trash]))
    create(index(:videos_communities_flags, [:trash]))
  end
end
