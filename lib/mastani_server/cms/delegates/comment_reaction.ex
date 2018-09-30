defmodule MastaniServer.CMS.Delegate.CommentReaction do
  import MastaniServer.CMS.Utils.Matcher

  alias Helper.ORM
  alias MastaniServer.Accounts

  def like_comment(thread, comment_id, %Accounts.User{id: user_id}) do
    feel_comment(thread, comment_id, user_id, :like)
  end

  def undo_like_comment(thread, comment_id, %Accounts.User{id: user_id}) do
    undo_feel_comment(thread, comment_id, user_id, :like)
  end

  def dislike_comment(thread, comment_id, %Accounts.User{id: user_id}) do
    feel_comment(thread, comment_id, user_id, :dislike)
  end

  def undo_dislike_comment(thread, comment_id, %Accounts.User{id: user_id}) do
    undo_feel_comment(thread, comment_id, user_id, :dislike)
  end

  defp merge_thread_comment_id(:post_comment, comment_id), do: %{post_comment_id: comment_id}
  defp merge_thread_comment_id(:video_comment, comment_id), do: %{video_comment_id: comment_id}

  defp feel_comment(thread, comment_id, user_id, feeling)
       when valid_feeling(feeling) do
    with {:ok, action} <- match_action(thread, feeling) do
      clause = Map.merge(%{user_id: user_id}, merge_thread_comment_id(thread, comment_id))
      # clause = %{post_comment_id: comment_id, user_id: user_id}

      case ORM.find_by(action.reactor, clause) do
        {:ok, _} ->
          {:error, "user has #{to_string(feeling)}d this comment"}

        {:error, _} ->
          action.reactor |> ORM.create(clause)

          ORM.find(action.target, comment_id)
      end
    end
  end

  defp undo_feel_comment(thread, comment_id, user_id, feeling) do
    with {:ok, action} <- match_action(thread, feeling) do
      clause = Map.merge(%{user_id: user_id}, merge_thread_comment_id(thread, comment_id))
      # clause = %{post_comment_id: comment_id, user_id: user_id}
      ORM.findby_delete(action.reactor, clause)
      ORM.find(action.target, comment_id)
    end
  end
end
