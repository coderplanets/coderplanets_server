defmodule GroupherServer.Repo.Migrations.CreateCmsRepos do
  use Ecto.Migration

  def change do
    create table(:cms_repos) do
      add(:title, :string)
      add(:desc, :text)
      add(:readme, :text)
      add(:language, :string)
      add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)

      add(:repo_link, :string)
      add(:repo_author, :string)

      add(:producer, :string)
      add(:producer_link, :string)

      add(:repo_star_count, :integer)
      add(:repo_fork_count, :integer)
      add(:repo_watch_count, :integer)

      add(:views, :integer, default: 0)
      add(:last_fetch_time, :utc_datetime)

      add(:pin, :boolean, default: false)
      add(:trash, :boolean, default: false)

      timestamps()
    end
  end
end
