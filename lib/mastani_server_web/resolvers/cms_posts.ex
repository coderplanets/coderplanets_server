defmodule MastaniServerWeb.Resolvers.CMS.Post do
  alias MastaniServer.CMS

  def all_posts(_root, _args, _info) do
    posts = CMS.list_cms_posts()
    {:ok, posts}
  end

  def create_post(_root, args, %{context: %{current_user: user}}) do
    # IO.inspect(user, label: "create_post current_user")
    # IO.inspect(args, label: "create_post args")

    case CMS.create_post(%CMS.Author{user_id: user.id}, args) do
      {:ok, post} ->
        {:ok, post}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_post(_root, _args, _info) do
    {:error, "Access denied"}
  end
end
