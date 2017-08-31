defmodule CoherenceOauth2.Test.Endpoint do
  use Phoenix.Endpoint, otp_app: :coherence_oauth2

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_binaryid_key",
    signing_salt: "JFbk5iZ6"

  plug CoherenceOauth2.Test.Router
end
