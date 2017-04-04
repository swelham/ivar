defmodule Ivar.TestMacros do
  defmacro has_header(conn, header) do
    quote do
      Enum.member?(unquote(conn).req_headers, unquote(header))
    end
  end
  
  defmacro has_multipart_header(conn) do
    quote do
      unquote(conn).req_headers
      |> Enum.find(& elem(&1, 0) == "content-type")
      |> elem(1)
      |> String.starts_with?("multipart/form-data;")
    end
  end
end