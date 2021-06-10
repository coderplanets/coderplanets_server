defmodule GroupherServer.Repo.Migrations.AddBodyHtmlToArtilces do
  use Ecto.Migration

  def change do
    alter(table(:cms_posts), do: modify(:body, :text))
    alter(table(:cms_jobs), do: modify(:body, :text))
    alter(table(:cms_repos), do: modify(:body, :text))
    alter(table(:cms_blogs), do: modify(:body, :text))

    alter(table(:cms_posts), do: add(:body_html, :text))
    alter(table(:cms_jobs), do: add(:body_html, :text))
    alter(table(:cms_repos), do: add(:body_html, :text))
    alter(table(:cms_blogs), do: add(:body_html, :text))
  end
end
