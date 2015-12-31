defmodule InstapaperToPocket.PocketImporter do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call([link: link, text: text], _from, state) do
    HTTPoison.start
    payload = Poison.encode!(%{
      "consumer_key" => Application.get_env(:instapaper_to_pocket, :pocket_consumer_key),
      "access_token" => Application.get_env(:instapaper_to_pocket, :pocket_access_token),
      "url" => link,
      "title" => text
    })
    headers = %{
      "Content-Type" => "application/json; charset=UTF-8",
      "X-Accept" => "application/json"
    }
    {:ok, response} = HTTPoison.post("https://getpocket.com/v3/add", payload, headers)

    IO.puts "import #{link} #{response.status_code}"
    {:reply, response.status_code, state}
  end

  def import(pid, opts) do
    GenServer.call(pid, opts)
  end
end
