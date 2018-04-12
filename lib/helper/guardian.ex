defmodule Helper.Guardian do
  use Guardian, otp_app: :mastani_server

  @token_expireation 24 * 14

  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  def resource_from_claims(claims) do
    {:ok, %{id: claims["sub"]}}
  end

  def jwt_encode(source, args \\ %{}) do
    encode_and_sign(source, args, ttl: {@token_expireation, :hour})
  end

  # jwt_decode
  def jwt_decode(token) do
    resource_from_token(token)
  end
end
