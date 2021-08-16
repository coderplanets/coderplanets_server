defmodule GroupherServer.Repo.Migrations.AddExtraToTags do
  use Ecto.Migration

  def change do
    alter table(:article_tags) do
      add(:extra, {:array, :string})
    end
  end
end
