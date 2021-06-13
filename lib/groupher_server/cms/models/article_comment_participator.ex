defmodule GroupherServer.CMS.Model.ArticleCommentParticipator do
  @moduledoc false

  use Ecto.Schema

  alias GroupherServer.Accounts.Model.User

  # alias CMS.Model.{
  #   Post,
  #   Job,
  #   CommentUpvote
  # }

  # alias Helper.HTML

  # @required_fields ~w(user_id)a
  # @optional_fields ~w(post_id job_id)a

  embedded_schema do
    # field(:reply_time, :string)

    belongs_to(:user, User)
  end
end
