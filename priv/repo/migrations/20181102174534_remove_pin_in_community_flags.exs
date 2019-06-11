defmodule GroupherServer.Repo.Migrations.RemovePinInCommunityFlags do
  use Ecto.Migration

  def change do
    alter table(:posts_communities_flags) do
      remove(:pin)
      remove(:refined)
    end

    alter table(:jobs_communities_flags) do
      remove(:pin)
    end

    alter table(:videos_communities_flags) do
      remove(:pin)
    end

    alter table(:repos_communities_flags) do
      remove(:pin)
    end
  end
end
