defmodule CoherenceAssent.GoogleTest do
  use CoherenceAssent.Test.ConnCase

  import OAuth2.TestHelpers
  alias CoherenceAssent.Strategy.Google

  setup %{conn: conn} do
    conn = session_conn(conn)

    bypass = Bypass.open
    config = [site: bypass_server(bypass),
              token_url: "/o/oauth2/token"]
    params = %{"code" => "test", "redirect_uri" => "test"}

    {:ok, conn: conn, config: config, params: params, bypass: bypass}
  end

  describe "callback/2" do
    test "normalizes data", %{conn: conn, config: config, params: params, bypass: bypass} do
      Bypass.expect_once bypass, "POST", "/o/oauth2/token", fn conn ->
        send_resp(conn, 200, Poison.encode!(%{access_token: "access_token"}))
      end

      Bypass.expect_once bypass, "GET", "/people/me/openIdConnect", fn conn ->
        user = %{"kind" => "plus#personOpenIdConnect",
                 "gender" => "",
                 "sub" => "1",
                 "name" => "Dan Schultzer",
                 "given_name" => "Dan",
                 "family_name" => "Schultzer",
                 "profile" => "https://example.com/profile",
                 "picture" => "https://example.com/images/profile.jpg",
                 "email" => "foo@example.com",
                 "email_verified" => "true",
                 "locale" => "en-US",
                 "hd" => "example.com"}
        Plug.Conn.resp(conn, 200, Poison.encode!(user))
      end

      expected = %{"email" => "foo@example.com",
                   "image" => "https://example.com/images/profile.jpg",
                   "name" => "Dan Schultzer",
                   "first_name" => "Dan",
                   "last_name" => "Schultzer",
                   "domain" => "example.com",
                   "uid" => "1",
                   "urls" => %{"Google" => "https://example.com/profile"}}

      {:ok, %{user: user}} = Google.callback(conn: conn,
                                             config: config,
                                             params: params)
      assert expected == user
    end
  end
end
