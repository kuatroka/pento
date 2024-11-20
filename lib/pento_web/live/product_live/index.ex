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
    {:noreply, assign(socket, suggestions: [])}
  end

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

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)
    {:ok, _} = Catalog.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end
end
