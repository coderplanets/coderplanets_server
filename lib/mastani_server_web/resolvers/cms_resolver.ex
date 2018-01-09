defmodule MastaniServerWeb.Resolvers.CMS do
  alias MastaniServer.CMS
  alias MastaniServer.Utils.Hepler

  def all_posts(_root, _args, _info) do
    posts = CMS.list_cms_posts()
    {:ok, posts}
  end

  def create_post(_root, args, %{context: %{current_user: user}}) do
    CMS.create_post(%CMS.Author{user_id: user.id}, args) |> Hepler.orm_resp()
  end

  # TODO: use middleware
  def create_post(_root, _args, _info), do: Hepler.access_deny(:login)

  def start_post(_root, %{post_id: post_id}, %{context: %{current_user: user}}) do
    CMS.do_reaction(:post, :star, post_id, user.id) |> Hepler.orm_resp()
  end

  def start_post(_root, _args, _info), do: Hepler.access_deny(:login)

  def unstar_post(_root, %{post_id: post_id}, %{context: %{current_user: user}}) do
    CMS.undo_reaction(:post, :star, post_id, user.id) |> Hepler.orm_resp()
  end

  def unstart_post(_root, _args, _info), do: Hepler.access_deny(:login)

  def favorite_post(_root, %{post_id: post_id}, %{context: %{current_user: user}}) do
    CMS.do_reaction(:post, :favorite, post_id, user.id) |> Hepler.orm_resp()
  end

  def favorite_post(_root, _args, _info), do: Hepler.access_deny(:login)

  def unfavorite_post(_root, %{post_id: post_id}, %{context: %{current_user: user}}) do
    CMS.undo_reaction(:post, :favorite, post_id, user.id) |> Hepler.orm_resp()
  end

  def unfavorite_post(_root, _args, _info), do: Hepler.access_deny(:login)

  def reaction_users(_root, %{type: type, id: id, page: page, size: size}, _info) do
    CMS.reaction_users(type, :favorite2, id, page, size) |> Hepler.orm_resp()
  end

  def favorites_users(root, _args, _info) do
    CMS.favorite_users(root.id) |> Hepler.orm_resp()
  end

  def delete_post(_root, %{post_id: post_id}, _info) do
    CMS.delete_content(:post, post_id) |> Hepler.orm_resp()
  end

  def comment_post(_root, %{post_id: post_id, body: body}, _info) do
    CMS.comment_post(post_id, body) |> Hepler.orm_resp()
  end

  def create_comment(_root, %{body: body}, _info) do
    CMS.create_comment(%{body: body}) |> Hepler.orm_resp()
  end

  def delete_comment(_root, %{id: id}, _info) do
    CMS.delete_content(:comment, id) |> Hepler.orm_resp()
  end
end
