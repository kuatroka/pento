defmodule Pento.Promo do
  alias Pento.Promo.Recipient

  def change_recipient(%Recipient{} = recipient, attrs \\ %{}) do
    Recipient.changeset(recipient, attrs)
  end

  def send_promo(%Recipient{} = recipient, attrs) do
    # sent email to promo recipient
    # For demonstration purposes, we'll assume the email sending is successful
    {:ok, %Recipient{}}
  end
end
