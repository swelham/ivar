defmodule IvarTest.QueryString do
  use ExUnit.Case, async: true
  doctest Ivar.QueryString

  alias Ivar.QueryString
  
  test "put/2 should put a keyword list of values" do
    result = QueryString.put(%{}, one: "two", three: "four")
    
    assert result == %{query: %{"one" => "two", "three" => "four"}}
  end

  test "put/2 should put a flat map of values" do
    result = QueryString.put(%{}, %{one: "two", three: "four"})
    
    assert result == %{query: %{"one" => "two", "three" => "four"}}
  end

  test "put/2 should put a flat map of values with binary keys" do
    result = QueryString.put(%{}, %{"one" => "two", "three" => "four"})
    
    assert result == %{query: %{"one" => "two", "three" => "four"}}
  end

  test "put/2 should put a list of 2 element tuples" do
    result = QueryString.put(%{}, [{"one", "two"}, {:three, "four"}])
    
    assert result == %{query: %{"one" => "two", "three" => "four"}}
  end
end