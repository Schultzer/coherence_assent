defmodule CoherenceAssent do
  @doc false
  def config() do
    Application.get_env(:coherence_assent, CoherenceAssent, [])
  end

  @doc false
  def config(provider) do
    providers!()
    |> Keyword.get(String.to_atom(provider), nil)
  end

  @doc false
  def repo, do: Coherence.Config.repo

  @doc false
  def providers! do
    Application.get_env(:coherence_assent, :providers) || raise "CoherenceAssent is missing the :providers configuration!"
  end

  defmodule CallbackError do
    defexception [:message, :error, :error_uri]
  end

  defmodule CallbackCSRFError do
    defexception message: "CSRF detected"
  end

  defmodule RequestError do
    defexception [:message, :error]
  end
end
