defmodule GroupherServer.Repo.Migrations.CreateGithubUsers do
  use Ecto.Migration

  def change do
    create table(:github_users) do
      add(:github_id, :string)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:login, :string)
      add(:avatar_url, :string)
      add(:url, :string)
      add(:html_url, :string)
      add(:name, :string)
      add(:company, :string)
      add(:blog, :string)
      add(:location, :string)
      add(:email, :string)
      add(:bio, :string)
      add(:public_repos, :integer)
      add(:public_gists, :integer)
      add(:followers, :integer)
      add(:following, :integer)

      timestamps()
    end

    create(unique_index(:github_users, [:github_id]))
  end
end
