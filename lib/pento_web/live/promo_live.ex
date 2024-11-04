defmodule PentoWeb.PromoLive do
  use PentoWeb, :live_view
  alias Pento.Promo
  alias Pento.Promo.Recipient

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_recipient()
     |> assign_changeset()
    }
  end

  def assign_recipient(socket) do
    socket
    |> assign(:recipient, %Recipient{})
  end

  def assign_changeset(%{assigns: %{recipient: recipient}} = socket) do
    changeset = Promo.change_recipient(recipient)
    form = to_form(changeset)
    socket
    |> assign(:changeset, changeset)
    |> assign(:form, form)
  end

  def handle_event("validate",
      %{"recipient" => recipient_params},
      %{assigns: %{recipient: recipient}} = socket) do
      changeset =
        recipient
        |> Promo.change_recipient(recipient_params)
        |> Map.put(:action, :validate)
      form = to_form(changeset)
      {:noreply, assign(socket, changeset: changeset, form: form)}
  end

  def handle_event("save",
      %{"recipient" => recipient_params},
      %{assigns: %{recipient: recipient}} = socket) do
      case Promo.send_promo(recipient, recipient_params) do
        {:ok, _recipient} ->
          {:noreply, socket |> put_flash(:info, "Promo code sent successfully!") |> push_navigate(to: "/")}
        {:error, changeset} ->
          form = to_form(changeset)
          {:noreply, assign(socket, changeset: changeset, form: form)}
      end
  end
end
