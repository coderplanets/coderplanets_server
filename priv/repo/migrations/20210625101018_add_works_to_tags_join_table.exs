defmodule GroupherServer.Repo.Migrations.AddWorksToTagsJoinTable do
  use Ecto.Migration

  def change do
    alter table(:articles_join_tags) do
      add(:works_id, references(:cms_works, on_delete: :delete_all))
    end
  end
end
