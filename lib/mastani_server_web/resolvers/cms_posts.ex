defmodule MastaniServerWeb.Resolvers.CMS.Post do
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
  def create_post(_root, _args, _info) do
    {:error, "Access denied"}
  end

  # def start_post(_root, args, _info) do
  def start_post(_root, %{user_id: user_id, post_id: post_id}, _info) do
    CMS.star_content(:post, post_id, user_id) |> Hepler.orm_resp()
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

end
