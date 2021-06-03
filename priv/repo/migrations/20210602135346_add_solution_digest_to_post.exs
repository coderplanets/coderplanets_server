defmodule GroupherServer.Repo.Migrations.AddSolutionDigestToPost do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:solution_digest, :string)
    end
  end
end
