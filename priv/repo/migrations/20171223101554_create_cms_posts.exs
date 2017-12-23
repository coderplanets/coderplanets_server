defmodule MastaniServer.Repo.Migrations.CreateCmsPosts do
  use Ecto.Migration

  def change do
    create table(:cms_posts) do
      add :title, :string
      add :desc, :text
      add :body, :text
      add :viewsCount, :integer
      add :isRefined, :boolean, default: false, null: false
      add :isSticky, :boolean, default: false, null: false
      add :viewerCanStar, :boolean, default: false, null: false
      add :viewerCanWatch, :string
      add :viewerCanCollect, :string

      timestamps()
    end

  end
end
