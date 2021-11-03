defmodule Helper.Guardian do
  @moduledoc """
  This module defines some helper function used by
  encode/decode jwt
  NOTE:  You can use `mix guardian.gen.secret` to get one
  see: https://github.com/ueberauth/guardian
  """
  use Guardian, otp_app: :groupher_server

  @token_expireation 24 * 30

  @spec subject_for_token(atom | %{id: any}, any) :: {:ok, binary}
  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  @spec resource_from_claims(nil | keyword | map) :: {:ok, %{id: any}}
  def resource_from_claims(claims) do
    {:ok, %{id: claims["sub"]}}
  end

  @spec jwt_encode(any, map) :: {:error, any} | {:ok, binary, map}
  def jwt_encode(source, args \\ %{}) do
    encode_and_sign(source, args, ttl: {@token_expireation, :hour})
  end

  # jwt_decode
  @spec jwt_decode(binary) :: {:error, any} | {:ok, any, map}
  def jwt_decode(token) do
    resource_from_token(token)
  end
end
