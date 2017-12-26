defmodule MastaniServerWeb.Resolvers.CMS.Post do
  alias MastaniServer.CMS
  alias MastaniServer.Accounts
  # ensure_author_exists

  def all_posts(_root, _args, _info) do
    posts = CMS.list_cms_posts()
    {:ok, posts}
  end

  def create_post(_root, args, _info) do
    # IO.inspect args, label: "create_post args"
    # author = require_existing_author(%Accounts.User{id: 60}) # todo: use current_User context

    case CMS.create_post(args) do
      {:ok, post} ->
        {:ok, post}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
