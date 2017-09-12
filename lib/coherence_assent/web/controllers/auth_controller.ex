defmodule CoherenceAssent.AuthController do
  @moduledoc false
  use Coherence.Web, :controller

  alias CoherenceAssent.Callback
  alias CoherenceAssent.Controller
  import Phoenix.Naming, only: [humanize: 1]

  plug Coherence.RequireLogin when action in ~w(destroy)a

  def index(conn, %{"provider" => provider}) do
    config = provider
             |> Controller.get_config!()
             |> Keyword.put(:redirect_uri, redirect_uri(conn, provider))

    {:ok, %{conn: conn, url: url}} = Controller.call_strategy!(config,
                                                               :authorize_url,
                                                               [[conn: conn,
                                                                 config: config]])

    redirect(conn, external: url)
  end

  def callback(conn, %{"provider" => provider} = params) do
    config = Controller.get_config!(provider)
    params = %{"redirect_uri" => redirect_uri(conn, provider)}
             |> Map.merge(params)

    config
    |> Controller.call_strategy!(:callback, [[conn: conn, config: config, params: params]])
    |> callback_handler(provider, params)
  end

  def delete(conn, %{"provider" => provider}) do
    conn
    |> Coherence.current_user()
    |> CoherenceAssent.UserIdentities.delete_identity_from_user(provider)
    |> case do
         {:ok, _} ->
           msg = Coherence.Messages.backend().authentication_has_been_removed(%{provider: humanize(provider)})
           put_flash(conn, :info, msg)

         {:error, %{errors: [user: {"needs password", []}]}} ->
           msg = Coherence.Messages.backend().identity_cannot_be_removed_missing_user_password()
           put_flash(conn, :error, msg)
       end
    |> redirect(to: Controller.get_route(conn, :registration_path, :edit))
  end

  defp redirect_uri(conn, provider) do
    Controller.get_route(conn, :coherence_assent_auth_url, :callback, [provider])
  end

  defp callback_handler({:ok, %{conn: conn, user: user}}, provider, params) do
    conn
    |> Coherence.current_user()
    |> Callback.handler(provider, user)
    |> Controller.callback_response(conn, provider, user, params)
  end
  defp callback_handler({:error, %{error: error}}, _provider, _params),
    do: raise error
end
