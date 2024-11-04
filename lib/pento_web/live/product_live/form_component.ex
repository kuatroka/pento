defmodule PentoWeb.ProductLive.FormComponent do
  use PentoWeb, :live_component

  alias Pento.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage product records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="product-form"
        multipart
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:unit_price]} type="number" label="Unit price" step="any" />
        <.input field={@form[:sku]} type="number" label="SKU" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Product</.button>
        </:actions>
        <div phx-drop-target={@uploads.image.ref} class="dropzone">
          <.label>Upload image</.label>
          <.live_file_input upload={@uploads.image} />
        </div>

        <%= for image <- @uploads.image.entries do %>
        <div class="mt-5">
          <.live_img_preview entry={image} width="60"/>
        </div>
        <progress value={image.progress} max="100"/>

          <%= for error <- upload_errors(@uploads.image, image) do %>
          <.error> <%= error %> </.error>
          <% end %>
        <% end %>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{product: product} = assigns, socket) do

    {:ok,
      socket
      |> assign(assigns)
      |> assign_new(:form, fn ->
        to_form(Catalog.change_product(product))
      end)
      |> allow_upload(:image,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 9_000_000,
        auto_upload: true)
    }
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset = Catalog.change_product(socket.assigns.product, product_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, product_params) do
    case Catalog.update_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})

        {:noreply,
          socket
          |> put_flash(:info, "Product updated successfully")
          |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_product(socket, :new, product_params) do
    case Catalog.create_product(product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})

        {:noreply,
          socket
          |> put_flash(:info, "Product created successfully")
          |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
