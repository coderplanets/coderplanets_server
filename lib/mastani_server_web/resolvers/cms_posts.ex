defmodule MastaniServerWeb.Resolvers.CMS.Post do
  alias MastaniServer.CMS
  alias MastaniServer.Accounts
  # ensure_author_exists

  def all_posts(_root, _args, _info) do
    posts = CMS.list_cms_posts()
    {:ok, posts}
  end

  def create_post(_root, args, _info) do
    IO.inspect args, label: "create_post args"
    author = require_existing_author(%Accounts.User{id: 39}) # todo: use current_User context

    IO.inspect author, label: "create_post author"
    case CMS.create_post(author, args) do
      {:ok, link} ->
        {:ok, link}

      _error ->
        {:error, "could not create post"}
    end
  end

  defp require_existing_author(%Accounts.User{} = user) do
    author = CMS.ensure_author_exists(user)
    author
  end
end
