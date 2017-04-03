defmodule Ivar.Auth do
  @moduledoc """
  Ivar.Auth manages the authentication credentials used for a request
  """
  
  @doc """
  Puts the given `credentials` under `auth_type` into the existing `request` map
  
  Args
  
  * `request` - the map used to store the credentials, usually created via `Ivar.new/2`
  * `credentials` - the credentials to be used for authentication
  * `auth_type` - an atom for the type of authentication to be used (`:basic` or `:bearer`)
  
  Credentials
  
  * `:basic` auth tuple - `{"username", "password"}`
  * `:bearer` token - `"some.token"`
  
  Usage
  
      iex> Ivar.Auth.put(%{}, {"user", "pass"}, :basic)
      %{auth: {"authorization", "basic dXNlcjpwYXNz"}}
  """
  @spec put(map, {tuple | binary}, atom) :: map
  def put(request, credentials, auth_type),
    do: put_auth(request, credentials, auth_type)
  
  defp put_auth(request, token, :bearer) do
    header = auth_header("bearer #{token}") 
    Map.put(request, :auth, header)
  end
  defp put_auth(request, {user, pass}, :basic) do
    encoded = Base.encode64("#{user}:#{pass}")
    header = auth_header("basic #{encoded}")
    Map.put(request, :auth, header)
  end
    
  defp auth_header(value), do: {"authorization", value}
end