defmodule IvarTest.Headers do
  use ExUnit.Case, async: true
  doctest Ivar.Headers

  alias Ivar.Headers
  
  test "put_headers/2 should put single tuple header" do
    header = {"header-1", "one"}
    
    result = Headers.put(%{}, header)

    assert result == %{headers: %{"header-1" => "one"}}
  end
  
  test "put_headers/2 should put keyword list of headers" do
    headers = ["header-1": "one", header_two: "two"]
    
    result = Headers.put(%{}, headers)

    assert result == %{headers: %{"header-1" => "one", "header_two" => "two"}}
  end

  test "put_headers/2 should put map of headers" do
    headers = %{"header-1" => "one", header_two: "two"}
    
    result = Headers.put(%{}, headers)

    assert result == %{headers: %{"header-1" => "one", "header_two" => "two"}}
  end
  
  test "put_headers/2 should put list of key/value tuple header" do
    headers = [{"header-1", "one"}, {:header_two, "two"}]
    
    result = Headers.put(%{}, headers)

    assert result == %{headers: %{"header-1" => "one", "header_two" => "two"}}
  end
  
  test "put_headers/3 should put binary key and value header" do
    result = Headers.put(%{}, "header-1", "one")

    assert result == %{headers: %{"header-1" => "one"}}
  end
  
  test "put_headers/3 should put atom key and value header" do
    result = Headers.put(%{}, :header_one, "one")

    assert result == %{headers: %{"header_one" => "one"}}
  end
end