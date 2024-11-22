defmodule PentoWeb.CikTableDuckDBLive do
  use PentoWeb, :live_view
  alias Duckdbex

  @db_path "/Users/yo_macbook/Documents/app_data/TEST_DUCKDB/TEST_DUCKDB_FILE_FULL.duckdb" # Replace with your DuckDB file path
  @page_size 10

  @impl true
  def mount(_params, _session, socket) do
    case Duckdbex.open(@db_path) do  # Open the DuckDB database
      {:ok, db} ->
        {:ok, conn} = Duckdbex.connection(db) # Create a connection

        {:ok, result} = Duckdbex.query(conn, "SELECT cik, cik_name, cik_ticker FROM cik_md")

        rows = Duckdbex.fetch_all(result)
        total_pages = ceil(length(rows) / @page_size)

        socket =
          socket
          |> assign(page: 1, total_pages: total_pages, all_rows: rows, db: db, conn: conn) #

          |> stream(:rows, [], dom_id: &"cik-#{Enum.at(&1, 0)}")

        {:ok, load_page(socket, rows, 1)}

      {:error, reason} ->
        {:ok, assign(socket, error: "Failed to open DuckDB database: #{reason}")}
    end
  end

  @impl true
  def handle_event("next_page", _, socket) do
    %{page: page, total_pages: total_pages, all_rows: rows} = socket.assigns
    new_page = min(page + 1, total_pages)
    {:noreply, load_page(socket, rows, new_page)}
  end

  @impl true
  def handle_event("prev_page", _, socket) do
    %{page: page, all_rows: rows} = socket.assigns
    new_page = max(page - 1, 1)
    {:noreply, load_page(socket, rows, new_page)}
  end

  defp load_page(socket, rows, page) do
    start_index = (page - 1) * @page_size
    page_rows = Enum.slice(rows, start_index, @page_size)

    socket
    |> assign(page: page)
    |> stream(:rows, page_rows, reset: true)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>CIK Table (DuckDB)</h1>
      <%= if assigns[:error] do %>
        <p><%= @error %></p>
      <% else %>
        <table>
          <thead>
            <tr>
              <th>CIK</th>
              <th>CIK Name</th>
              <th>CIK Ticker</th>
            </tr>
          </thead>
          <tbody id="rows" phx-update="stream">
            <tr :for={{dom_id, row} <- @streams.rows} id={dom_id}>
              <td><%= row.cik %></td>
              <td><%= row.cik_name %></td>
              <td><%= row.cik_ticker %></td>
            </tr>
          </tbody>
        </table>
        <div>
          <button phx-click="prev_page" disabled={@page == 1}>←</button>
          <span>Page <%= @page %> of <%= @total_pages %></span>
          <button phx-click="next_page" disabled={@page == @total_pages}>→</button>
        </div>
      <% end %>
    </div>
    """
  end

   @impl true
  def terminate(_reason, socket) do
    Duckdbex.close(socket.assigns.db) # Close the database connection when the LiveView
  end

end
