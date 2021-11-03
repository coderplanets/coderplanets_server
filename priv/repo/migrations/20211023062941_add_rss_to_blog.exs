defmodule GroupherServer.Repo.Migrations.AddRssToBlog do
  use Ecto.Migration

  def change do
    alter table(:cms_blogs) do
      add(:rss, :string)
    end
  end
end
