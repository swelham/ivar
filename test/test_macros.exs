defmodule Ivar.TestMacros do
  defmacro has_header(req, header) do
    quote do
      Enum.member?(unquote(req).headers, unquote(header))
    end
  end
  
  defmacro has_multipart_header(req) do
    quote do
      unquote(req).headers
      |> Enum.find(& elem(&1, 0) == "content-type")
      |> elem(1)
      |> String.starts_with?("multipart/form-data")
    end
  end
end