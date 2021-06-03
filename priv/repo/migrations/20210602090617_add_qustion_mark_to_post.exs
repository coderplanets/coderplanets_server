defmodule GroupherServer.Repo.Migrations.AddQustionMarkToPost do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:is_question, :boolean, default: false)
      add(:is_solved, :boolean, default: false)
    end
  end
end
