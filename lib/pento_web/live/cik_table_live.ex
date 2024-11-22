defmodule PentoWeb.CikTableLive do
  use PentoWeb, :live_view
  alias Explorer.DataFrame

  @parquet_file_path "data/MD_03_CIK_NAME_TICKER_FILE.parquet"
  @page_size 10

  @impl true
  def mount(_params, _session, socket) do
    case DataFrame.from_parquet(@parquet_file_path) do
      {:ok, df} ->
        selected_df =
          df
          |> DataFrame.select(["cik", "cik_name", "cik_ticker"])

        rows = DataFrame.to_rows(selected_df, atom_keys: true)
        total_pages = ceil(length(rows) / @page_size)

        socket =
          socket
          |> assign(page: 1, total_pages: total_pages, all_rows: rows)
          |> stream(:rows, [], dom_id: &"cik-#{&1.cik}")

        {:ok, load_page(socket, rows, 1)}

      {:error, reason} ->
        {:ok, assign(socket, error: "Failed to load data from Parquet file: #{reason}")}
    end
  end

  @impl true
  def handle_event("next_page", _, socket) do
    %{page: page, total_pages: total_pages} = socket.assigns
    new_page = min(page + 1, total_pages)
    {:noreply, load_page(socket, socket.assigns.all_rows, new_page)}
  end

  @impl true
  def handle_event("prev_page", _, socket) do
    %{page: page} = socket.assigns
    new_page = max(page - 1, 1)
    {:noreply, load_page(socket, socket.assigns.all_rows, new_page)}
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
      <h1>CIK Table</h1>
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
end
