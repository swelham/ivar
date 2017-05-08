defmodule IvarTest.Auth do
  use ExUnit.Case, async: true
  doctest Ivar.Auth

  alias Ivar.Auth
  
  test "put/3 should put bearer auth" do
    result = Auth.put(%{}, "token", :bearer)
    
    assert result == %{auth: {"authorization", "Bearer token"}}
  end
  
  test "put/3 should put basic auth" do
    result = Auth.put(%{}, {"user", "pass"}, :basic)

    assert result == %{auth: {"authorization", "Basic dXNlcjpwYXNz"}}
  end
end