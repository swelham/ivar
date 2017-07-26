[![Build Status](https://travis-ci.org/swelham/ivar.svg?branch=master)](https://travis-ci.org/swelham/ivar) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/swelham/ivar.svg?branch=master)](https://beta.hexfaktor.org/github/swelham/ivar) [![Hex Version](https://img.shields.io/hexpm/v/ivar.svg)](https://hex.pm/packages/ivar) [![Join the chat at https://gitter.im/swelham/ivar](https://badges.gitter.im/swelham/ivar.svg)](https://gitter.im/swelham/ivar?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Ivar

Ivar is an adapter based HTTP client that provides the ability to build composable HTTP requests.

The key goals of Ivar are to allow requests to be constructed in a composable manner (pipeline friendly) and to simplify building, sending and receiving requests for a number of well known
http clients.

## Supported Adapters

| HTTP Client | Adapter |
| ----------- | ------- |
| HTTPoison | [ivar_httpoison](https://github.com/swelham/ivar_httpoison) |

## Usage

Add `ivar` to your list of dependencies in `mix.exs`, plus the http adapter you are going to use:

```elixir
def deps do
  [
    {:ivar, "~> 0.9.0"},
    {:ivar_httpoison, "~> 0.1.0"}
  ]
end
```

Setup up the config for your chosen adapater

```elixir
config :ivar,
  :adapter Ivar.HTTPoison
```

### Basic usage


```elixir
Ivar.get("https://example.com")
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
    {:ivar, "~> 0.9.0"},
    {:poison, "~> 3.0"},
    ...
  ]
end
```
You can then specify that you want to send JSON when putting the request body. If 
the response contains the `application/json` content type header, the `Ivar.unpack` 
function will then decode the response for you.

```elixir
Ivar.post("https://some-echo-server")
|> Ivar.put_body(%{some: "data"}, :json)
|> Ivar.send
|> Ivar.unpack
# {%{some: "data"}, %HTTPoison.Response{}}
```


### Real world example

This is simplified extract from a real world application where Ivar is being used to
send email via the mailgun service.

```elixir
url = "https://api.mailgun.net/v3/domain.com/messages"
mail_data = %{to: "someone@example.com", ...}
files = [{"inline", File.read!("elixir.png"), "elixir.png"}, ...]

Ivar.new(:post, url)
|> Ivar.put_auth({"api", "mailgun_api_key"}, :basic)
|> Ivar.put_body(mail_data, :url_encoded)
|> Ivar.put_files(files)
|> Ivar.send
```
