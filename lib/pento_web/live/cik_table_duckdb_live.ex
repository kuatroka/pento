defmodule PentoWeb.CikTableDuckDBLive do
  use PentoWeb, :live_view
  alias Duckdbex

  @db_path "/Users/yo_macbook/Documents/app_data/TEST_DUCKDB/TEST_DUCKDB_FILE_FULL.duckdb" # Replace with your DuckDB file path
  @page_size 10

  @impl true
  def mount(_params, _session, socket) do
    case Duckdbex.open(@db_path) do
      {:ok, db} ->
        {:ok, conn} = Duckdbex.connection(db)
        socket = assign(socket, db: db, conn: conn)
        {:ok, load_page(socket, 1)}

      {:error, reason} ->
        {:ok, assign(socket, error: "Failed to open DuckDB database: #{reason}")}
    end
  end

  @impl true
  def handle_event("next_page", _, socket) do
    %{page: page, total_pages: total_pages} = socket.assigns
    new_page = min(page + 1, total_pages)
    {:noreply, load_page(socket, new_page)}
  end

  @impl true
  def handle_event("prev_page", _, socket) do
    %{page: page} = socket.assigns
    new_page = max(page - 1, 1)
    {:noreply, load_page(socket, new_page)}
  end

  defp load_page(socket, page) do
    offset = (page - 1) * @page_size
    query = "SELECT cik, cik_name, cik_ticker FROM cik_md LIMIT #{@page_size} OFFSET #{offset}"
    IO.inspect(query, label: "Executing Query")
    case Duckdbex.query(socket.assigns.conn, query) do
      {:ok, result} ->
        case Duckdbex.query(socket.assigns.conn, query) do
          {:ok, result} ->
            {:ok, rows} =
              Duckdbex.fetch_all(result)
              |> Enum.with_index()
              |> Enum.map(fn row, index ->
                [cik, cik_name, cik_ticker] = Enum.map(row, &(&1 || ""))
                %{id: "row-#{index}-#{cik}", cik: cik, cik_name: cik_name, cik_ticker: cik_ticker}
              end)

            {:ok, result2} = Duckdbex.query(socket.assigns.conn, "SELECT count(*) FROM cik_md")
            {:ok, [[total_count]]} = Duckdbex.fetch_all(result2)
            total_pages = ceil(total_count / @page_size)

            socket
            |> assign(page: page, total_pages: total_pages)
            |> stream(:rows, rows, reset: true)

          {:error, reason} ->
            socket
            |> put_flash(:error, "Error fetching total count: #{reason}")
            |> assign(page: page, total_pages: 0)
            |> stream(:rows, [], reset: true)
        end

      {:error, reason} ->
        socket
        |> put_flash(:error, "Error fetching rows: #{reason}")
        |> assign(page: page, total_pages: 0)
        |> stream(:rows, [], reset: true)
    end
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
            <tr :for={{dom_id, %{cik: cik, cik_name: cik_name, cik_ticker: cik_ticker}} <- @streams.rows} id={dom_id}>
              <td><%= cik %></td>
              <td><%= cik_name %></td>
              <td><%= cik_ticker %></td>
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
  def terminate(_reason, %{assigns: %{db: db, conn: conn}}) do
    Duckdbex.close(conn)
    Duckdbex.close(db)
  end

end
