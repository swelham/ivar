[![Build Status](https://travis-ci.org/swelham/ivar.svg?branch=master)](https://travis-ci.org/swelham/ivar) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/swelham/ivar.svg?branch=master)](https://beta.hexfaktor.org/github/swelham/ivar) [![Hex Version](https://img.shields.io/hexpm/v/ivar.svg)](https://hex.pm/packages/ivar) [![Join the chat at https://gitter.im/swelham/ivar](https://badges.gitter.im/swelham/ivar.svg)](https://gitter.im/swelham/ivar?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Ivar

Ivar is a lightweight wrapper around HTTPoison that provides a fluent and composable way to build http requests.
The key goals of Ivar is to allow requests to be constructed in a composable manner (pipeline friendly) and to 
simplify building, sending and receiving requests.

## Usage

Add `ivar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ivar, "~> 0.2.0"}]
end
```

### Basic usage


```elixir
Ivar.new(:get, "https://example.com")
|> Ivar.send
|> Ivar.unpack
# {"<!doctype html>\n<html>...", %HTTPoison.Response{}}
```

### JSON encoding/decoding

Ivar uses the `Poison` library for encoding and decoding JSON, so make sure you
have it listed along side Ivar in your `mix.exs`.

```elixir
def deps do
  [
    {:ivar, "~> 0.2.0"},
    {:poison, "~> 3.0"}
  ]
end
```
You can then specify that you want to send JSON when putting the request body. If 
the response contains the `application/json` content type header, the `Ivar.unpack` 
function will then decode the response for you.

```elixir
Ivar.new(:post, "https://some-echo-server")
|> Ivar.put_body(%{some: "data"}, :json)
|> Ivar.send
|> Ivar.unpack
# {%{some: "data"}, %HTTPoison.Response{}}
```


### Real world example

This is simplified extract from a real world application where Ivar is being used to
send email via the mailgun service.

```elixir
url = "https://api.mailgun.net/v3/m.welham.online/messages"
mail_data = %{to: "someone@example.com", ...}
files = [{"inline", File.read!("elixir.png"), "elixir.png", "png"}, ...]

Ivar.new(:post, url)
|> Ivar.put_auth({"api", "mailgun_api_key"}, :basic)
|> Ivar.put_body(mail_data, :url_encoded)
|> Ivar.put_files(files)
|> Ivar.send
```