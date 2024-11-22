defmodule PentoWeb.ProductLive.Index do
  use PentoWeb, :live_view

  alias Pento.Catalog
  alias Pento.Catalog.Product
  alias Pento.Repo
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:products, Catalog.list_products())
      |> assign(:query, "")
      |> assign(:suggestions, [])
      |> assign(:selected_index, -1)
    {:ok, socket}
  end

  @impl true
  def handle_event("suggest", %{"query" => query}, socket) when byte_size(query) >= 2 do
    search_term = "%#{query}%"

    suggestions =
      from(p in Product,
        where: like(fragment("LOWER(?)", p.name), fragment("LOWER(?)", ^search_term)) or
               like(fragment("LOWER(?)", p.description), fragment("LOWER(?)", ^search_term)),
        select: %{id: p.id, name: p.name, description: p.description},
        limit: 5
      ) |> Repo.all()

    {:noreply, assign(socket, suggestions: suggestions)}
  end

  def handle_event("suggest", _, socket) do
    {:noreply, assign(socket, suggestions: [], selected_index: -1)}
  end

  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    new_index = min(
      socket.assigns.selected_index + 1,
      length(socket.assigns.suggestions) - 1
    )
    {:noreply, assign(socket, :selected_index, new_index)}
  end

  def handle_event("keydown", %{"key" => "ArrowUp"}, socket) do
    new_index = max(socket.assigns.selected_index - 1, -1)
    {:noreply, assign(socket, :selected_index, new_index)}
  end

  def handle_event("keydown", %{"key" => "Enter"}, socket) do
    if socket.assigns.selected_index >= 0 do
      suggestion = Enum.at(socket.assigns.suggestions, socket.assigns.selected_index)
      handle_event("search-select", %{"id" => suggestion.id}, socket)
    else
      {:noreply, socket}
    end
  end

  def handle_event("keydown", _, socket), do: {:noreply, socket}

  def handle_event("search-select", %{"id" => id}, socket) do
    {:noreply,
      socket
      |> assign(:suggestions, [])
      |> push_navigate(to: ~p"/products/#{id}")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Product")
    |> assign(:product, Catalog.get_product!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Product")
    |> assign(:product, %Product{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Products")
    |> assign(:product, nil)
  end

  @impl true
  def handle_info({PentoWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, stream_insert(socket, :products, product)}
  end


end
