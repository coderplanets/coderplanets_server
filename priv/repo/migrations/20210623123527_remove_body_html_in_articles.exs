defmodule GroupherServer.Repo.Migrations.RemoveBodyHtmlInArticles do
  use Ecto.Migration

  def change do
    alter(table(:cms_posts), do: remove(:body_html))
    alter(table(:cms_jobs), do: remove(:body_html))
    alter(table(:cms_blogs), do: remove(:body_html))
    alter(table(:cms_repos), do: remove(:body_html))
  end
end
