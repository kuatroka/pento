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

        <%!-- table #1 --%>
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




    <%!-- table #2 --%>

    <div class="relative overflow-x-auto shadow-md sm:rounded-lg">
        <table class="w-full text-sm text-left rtl:text-right text-gray-500 dark:text-gray-400">
            <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
                <tr>
                    <th scope="col" class="px-6 py-3">
                        CIK
                    </th>
                    <th scope="col" class="px-6 py-3">
                                      <div class="flex items-center">
                                          CIK NAME
                                          <a href="#"><svg class="w-3 h-3 ms-1.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M8.574 11.024h6.852a2.075 2.075 0 0 0 1.847-1.086 1.9 1.9 0 0 0-.11-1.986L13.736 2.9a2.122 2.122 0 0 0-3.472 0L6.837 7.952a1.9 1.9 0 0 0-.11 1.986 2.074 2.074 0 0 0 1.847 1.086Zm6.852 1.952H8.574a2.072 2.072 0 0 0-1.847 1.087 1.9 1.9 0 0 0 .11 1.985l3.426 5.05a2.123 2.123 0 0 0 3.472 0l3.427-5.05a1.9 1.9 0 0 0 .11-1.985 2.074 2.074 0 0 0-1.846-1.087Z"/>
                    </svg></a>
                                      </div>
                    </th>
                    <th scope="col" class="px-6 py-3">
                        <div class="flex items-center">
                            CIK TICKER
                                                <a href="#"><svg class="w-3 h-3 ms-1.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M8.574 11.024h6.852a2.075 2.075 0 0 0 1.847-1.086 1.9 1.9 0 0 0-.11-1.986L13.736 2.9a2.122 2.122 0 0 0-3.472 0L6.837 7.952a1.9 1.9 0 0 0-.11 1.986 2.074 2.074 0 0 0 1.847 1.086Zm6.852 1.952H8.574a2.072 2.072 0 0 0-1.847 1.087 1.9 1.9 0 0 0 .11 1.985l3.426 5.05a2.123 2.123 0 0 0 3.472 0l3.427-5.05a1.9 1.9 0 0 0 .11-1.985 2.074 2.074 0 0 0-1.846-1.087Z"/>
                          </svg></a>
                        </div>
                    </th>

                    <th scope="col" class="px-6 py-3">
                        <span class="sr-only">Edit</span>
                    </th>
                </tr>
            </thead>
            <tbody id="rows" phx-update="stream">
                <tr class="bg-white border-b dark:bg-gray-800 dark:border-gray-700" :for={{dom_id, %{cik: cik, cik_name: cik_name, cik_ticker: cik_ticker}} <- @streams.rows} id={dom_id}>
                <th scope="row" class="px-6 py-2 font-medium text-gray-900 whitespace-nowrap dark:text-white"><%= cik %></th>
                <td class="px-6 py-2"><%= cik_name %></td>
                <td class="px-6 py-2"><%= cik_ticker %></td>
                </tr>

            </tbody>
        </table>
        </div>




    </div>
    """
  end

end
