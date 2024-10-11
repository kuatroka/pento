defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view

  def mount(_params, _session, socket) do
    secret_number = :rand.uniform(10)
    {:ok, assign(socket, score: 0, message: "Make a guess: ", time: time(), secret_number: secret_number, won: false)}
  end


  ##################################
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <h1 class="text-center mb-4 text-4xl font-extrabold">Your score: <%= @score %></h1>
    <h2 class="text-center">
      <%= @message  %>
      It's  <%= @time %>
    </h2>
    <br/>
    <h2 class="text-center">
        <%= for n <- 1..10 do %>
          <.link class="bg-emerald-50 hover:bg-blue-700
          text-rose-900 font-bold py-2 px-4 border border-gray-300 rounded m-1"
          phx-click="guess" phx-value-number= {n} >
            <%= n %>
          </.link>
        <% end %>
    </h2>
    <%= if @won do %>
      <div class="text-center mt-4">
        <p class="p-4">You won! </p>
        <.link patch={~p"/guess"} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
          Restart Game
        </.link>
      </div>
    <% end %>
    """
  end

  def time() do
    DateTime.utc_now() |> to_string
  end

  ##################################
  def handle_event("guess", %{"number" => guess}, socket) do
    guess = String.to_integer(guess)
    {message, score, won} =
      cond do
        guess == socket.assigns.secret_number ->
          {"You guessed it! The number was #{guess}.", socket.assigns.score + 1, true}
        true ->
          {"Your guess: #{guess}. Wrong. Try again.", socket.assigns.score - 1, false}
      end
    time = time()
    {:noreply, assign(socket, message: message, score: score, time: time, won: won)}
  end
  ##################################



  def handle_params(_params, _uri, socket) do
    if _uri == "/guess" do
      secret_number = :rand.uniform(10)
      {:noreply, assign(socket, won: false, message: "Make a guess: ", secret_number: secret_number)}
    else
      {:noreply, socket}
    end
  end
end
