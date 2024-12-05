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
    IO.inspect("Next page clicked")
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

    <div>


    <div id="accordion-collapse" data-accordion="collapse" class="mt-4">
      <h2 id="accordion-collapse-heading-1">
        <button type="button" class="flex items-center justify-between w-full p-5 font-medium rtl:text-right text-gray-500 border border-b-0 border-gray-200 rounded-t-xl focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-800 dark:border-gray-700 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 gap-3" data-accordion-target="#accordion-collapse-body-1" aria-expanded="true" aria-controls="accordion-collapse-body-1">
          <span>What is Flowbite?</span>
          <svg data-accordion-icon class="w-3 h-3 rotate-180 shrink-0" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 10 6">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5 5 1 1 5"/>
          </svg>
        </button>
      </h2>
      <div id="accordion-collapse-body-1" class="hidden" aria-labelledby="accordion-collapse-heading-1">
        <div class="p-5 border border-b-0 border-gray-200 dark:border-gray-700 dark:bg-gray-900">
          <p class="mb-2 text-gray-500 dark:text-gray-400">Flowbite is an open-source library of interactive components built on top of Tailwind CSS including buttons, dropdowns, modals, navbars, and more.</p>
          <p class="text-gray-500 dark:text-gray-400">Check out this guide to learn how to <a href="/docs/getting-started/introduction/" class="text-blue-600 dark:text-blue-500 hover:underline">get started</a> and start developing websites even faster with components on top of Tailwind CSS.</p>
        </div>
      </div>
      <h2 id="accordion-collapse-heading-2">
        <button type="button" class="flex items-center justify-between w-full p-5 font-medium rtl:text-right text-gray-500 border border-b-0 border-gray-200 focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-800 dark:border-gray-700 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 gap-3" data-accordion-target="#accordion-collapse-body-2" aria-expanded="false" aria-controls="accordion-collapse-body-2">
          <span>Is there a Figma file available?</span>
          <svg data-accordion-icon class="w-3 h-3 rotate-180 shrink-0" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 10 6">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5 5 1 1 5"/>
          </svg>
        </button>
      </h2>
      <div id="accordion-collapse-body-2" class="hidden" aria-labelledby="accordion-collapse-heading-2">
        <div class="p-5 border border-b-0 border-gray-200 dark:border-gray-700">
          <p class="mb-2 text-gray-500 dark:text-gray-400">Flowbite is first conceptualized and designed using the Figma software so everything you see in the library has a design equivalent in our Figma file.</p>
          <p class="text-gray-500 dark:text-gray-400">Check out the <a href="https://flowbite.com/figma/" class="text-blue-600 dark:text-blue-500 hover:underline">Figma design system</a> based on the utility classes from Tailwind CSS and components from Flowbite.</p>
        </div>
      </div>
      <h2 id="accordion-collapse-heading-3">
        <button type="button" class="flex items-center justify-between w-full p-5 font-medium rtl:text-right text-gray-500 border border-gray-200 focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-800 dark:border-gray-700 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 gap-3" data-accordion-target="#accordion-collapse-body-3" aria-expanded="false" aria-controls="accordion-collapse-body-3">
          <span>What are the differences between Flowbite and Tailwind UI?</span>
          <svg data-accordion-icon class="w-3 h-3 rotate-180 shrink-0" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 10 6">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5 5 1 1 5"/>
          </svg>
        </button>
      </h2>
      <div id="accordion-collapse-body-3" class="hidden" aria-labelledby="accordion-collapse-heading-3">
        <div class="p-5 border border-t-0 border-gray-200 dark:border-gray-700">
          <p class="mb-2 text-gray-500 dark:text-gray-400">The main difference is that the core components from Flowbite are open source under the MIT license, whereas Tailwind UI is a paid product. Another difference is that Flowbite relies on smaller and standalone components, whereas Tailwind UI offers sections of pages.</p>
          <p class="mb-2 text-gray-500 dark:text-gray-400">However, we actually recommend using both Flowbite, Flowbite Pro, and even Tailwind UI as there is no technical reason stopping you from using the best of two worlds.</p>
          <p class="mb-2 text-gray-500 dark:text-gray-400">Learn more about these technologies:</p>
          <ul class="ps-5 text-gray-500 list-disc dark:text-gray-400">
            <li><a href="https://flowbite.com/pro/" class="text-blue-600 dark:text-blue-500 hover:underline">Flowbite Pro</a></li>
            <li><a href="https://tailwindui.com/" rel="nofollow" class="text-blue-600 dark:text-blue-500 hover:underline">Tailwind UI</a></li>
          </ul>
        </div>
      </div>
    </div>

    </div>
    """
  end
end
