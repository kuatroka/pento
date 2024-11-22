defmodule PentoWeb.CikTableDuckDBLive do
  use PentoWeb, :live_view
  alias Pento.DuckdbContext

  @impl true
  def mount(_params, _session, socket) do
    socket =
      case DuckdbContext.open_connection() do
        {:ok, %{conn: _conn} = connection} ->
          socket
          |> assign(connection: connection)
          |> load_page(1)

        {:error, reason} ->
          socket
          |> put_flash(:error, "Database connection failed: #{reason}")
          |> assign(error: reason)

        other ->
          socket
          |> put_flash(:error, "Unexpected error: #{inspect(other)}")
          |> assign(error: inspect(other))
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("next_page", _, socket) do
    IO.inspect("Next page clicked")
    %{page: page, total_pages: total_pages} = socket.assigns
    new_page = min(page + 1, total_pages)
    socket = load_page(socket, new_page)
    IO.inspect(socket)
    {:noreply, socket}
  end

  def handle_event("prev_page", _, socket) do
    IO.inspect("Next page clicked")
    %{page: page, total_pages: total_pages} = socket.assigns
    new_page = min(page - 1, total_pages)
    socket = load_page(socket, new_page)
    IO.inspect(socket)
    {:noreply, socket}
  end


  defp load_page(socket, page) do
    IO.inspect("Loading page #{page}")
    IO.inspect(socket.assigns)
    socket = assign(socket, :page, page)
    case DuckdbContext.fetch_cik_page(socket.assigns.connection.conn, page) do
      {:ok, %{rows: rows, page: page, total_pages: total_pages}} ->
        socket
        |> assign(page: page, total_pages: total_pages)
        |> stream(:rows, rows, reset: true)

      {:error, reason} ->
        socket
        |> put_flash(:error, "Error fetching data: #{reason}")
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

end
