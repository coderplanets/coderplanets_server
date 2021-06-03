defmodule GroupherServer.Repo.Migrations.AddSolutionDigestToComment do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:is_solution, :boolean, default: false)
    end
  end
end
