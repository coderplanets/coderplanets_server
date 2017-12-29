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

  # TODO: use middleware
  def create_post(_root, _args, _info) do
    {:error, "Access denied"}
  end

  # def start_post(_root, args, _info) do
  def start_post(_root, %{user_id: user_id, post_id: post_id}, _info) do
    case CMS.star_post(post_id, user_id) do
      {:ok, post} ->
        {:ok, post}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
