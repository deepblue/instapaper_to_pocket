defmodule InstapaperToPocket do
  alias InstapaperToPocket.PocketImporter

  def main(args) do
    init_pool

    args
    |> parse_args
    |> process
  end

  def process([html: filename]) do
    IO.puts "Reading #{filename}"

    File.read!(filename)
    |> Floki.find("ol li a")
    |> Enum.reverse
    |> Enum.map(&process_tag(&1))
    |> Enum.each(&Task.await(&1, :infinity))
  end
  def process([test: link]) do
    IO.puts "test #{link}"
    {:ok, pid} = PocketImporter.start_link([])
    PocketImporter.import(pid, [link: link, text: "TEST"])
  end
  def process(_) do
    IO.puts "No arguments given"
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args)
    options
  end

  defp process_tag({"a", [{"href", link}], [text]}) do
    Task.async fn ->
      :poolboy.transaction pool_name(), fn(pid) ->
        PocketImporter.import(pid, [link: link, text: text])
      end, :infinity
    end
  end

  defp init_pool do
    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, PocketImporter},
      {:size, 5},
      {:max_overflow, 0}
    ]

    {:ok, _pool} = :poolboy.start_link(poolboy_config)
  end

  defp pool_name do
    :pocket_importer
  end
end
