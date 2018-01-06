defmodule MastaniServerWeb.Resolvers.CMS.Post do
  alias MastaniServer.CMS
  alias MastaniServer.Utils.Hepler

  def all_posts(_root, _args, _info) do
    posts = CMS.list_cms_posts()
    {:ok, posts}
  end

  def create_post(_root, args, %{context: %{current_user: user}}) do
    CMS.create_post(%CMS.Author{user_id: user.id}, args) |> Hepler.deal_withit()
  end

  # TODO: use middleware
  def create_post(_root, _args, _info) do
    {:error, "Access denied"}
  end

  # def start_post(_root, args, _info) do
  def start_post(_root, %{user_id: user_id, post_id: post_id}, _info) do
    CMS.star_post(post_id, user_id) |> Hepler.deal_withit()
  end

  def delete_post(_root, %{post_id: post_id}, _info) do
    CMS.delete_content(post_id) |> Hepler.deal_withit()
  end
end
