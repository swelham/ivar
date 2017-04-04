defmodule IvarTest.Utilities do
  use ExUnit.Case, async: true
  doctest Ivar.Utilities

  alias Ivar.Utilities
  
  test "get_mime_type/1 should return mime-type for given extension" do
    mime = Utilities.get_mime_type("jpg")
    
    assert mime == "image/jpeg"
  end
  
  test "get_mime_type/1 should return custom mime-type" do
    mime = Utilities.get_mime_type("custom/type")
    
    assert mime == "custom/type"
  end
end