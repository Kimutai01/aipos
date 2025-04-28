defmodule AiposWeb.CustomerLive.Show do
  use AiposWeb, :live_view

  alias Aipos.Customers
  alias AiposWeb.Sidebar

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_user, socket.assigns.current_user)
      |> assign(
        :current_organization,
        get_current_organization(socket.assigns.current_user.organization_id)
      )
      |> assign(:active_page, "customers")
      |> assign(:purchase_history, [])
      |> assign(:loyalty_history, [])
      |> assign(:loyalty_tiers, sample_loyalty_tiers())

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    customer = Customers.get_customer!(id)

    purchase_history = generate_purchase_history()
    loyalty_history = generate_loyalty_history(customer)

    {:noreply,
     socket
     |> assign(:page_title, "Customer Details")
     |> assign(:customer, customer)
     |> assign(:purchase_history, purchase_history)
     |> assign(:loyalty_history, loyalty_history)}
  end

  @impl true
  def handle_event("add_loyalty_points", %{"points" => points_str}, socket) do
    {points, _} = Integer.parse(points_str)
    customer = socket.assigns.customer

    {:ok, updated_customer} =
      Customers.update_customer(customer, %{
        loyalty_points: customer.loyalty_points + points,
        membership_level: calculate_membership_level(customer.loyalty_points + points)
      })

    now = DateTime.utc_now()

    new_entry = %{
      id: :rand.uniform(1000),
      date: now,
      points: points,
      reason: "Manual adjustment",
      type: "credit"
    }

    updated_history = [new_entry | socket.assigns.loyalty_history]

    {:noreply,
     socket
     |> assign(:customer, updated_customer)
     |> assign(:loyalty_history, updated_history)
     |> put_flash(:info, "Added #{points} loyalty points to #{customer.name}'s account")}
  end

  @impl true
  def handle_event("close_customer_details", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/customers")}
  end

  defp get_current_organization(organization_id) do
    Aipos.Organizations.get_organization!(organization_id)
  end

  defp calculate_membership_level(points) do
    cond do
      points >= 2000 -> "Platinum"
      points >= 1000 -> "Gold"
      points >= 500 -> "Silver"
      true -> "Bronze"
    end
  end

  defp sample_loyalty_tiers do
    [
      %{name: "Bronze", min_points: 0, benefits: "Basic loyalty program benefits"},
      %{
        name: "Silver",
        min_points: 500,
        benefits: "5% discount on all purchases + Bronze benefits"
      },
      %{
        name: "Gold",
        min_points: 1000,
        benefits: "10% discount on all purchases + free delivery + Silver benefits"
      },
      %{
        name: "Platinum",
        min_points: 2000,
        benefits: "15% discount on all purchases + priority service + Gold benefits"
      }
    ]
  end

  defp generate_purchase_history do
    Enum.map(1..5, fn i ->
      items =
        Enum.map(1..:rand.uniform(5), fn _ ->
          product_names = ["Premium Coffee", "Chicken Sandwich", "Fresh Juice", "Breakfast Combo"]

          %{
            name: Enum.random(product_names),
            quantity: :rand.uniform(3),
            price: (:rand.uniform(20) + 5) * 50
          }
        end)

      total = Enum.reduce(items, 0, fn item, acc -> acc + item.quantity * item.price end)

      %{
        id: i,
        receipt_number: "S#{10000 + i}",
        date: Date.add(Date.utc_today(), -:rand.uniform(90)),
        items: items,
        total: total,
        payment_method: Enum.random(["Cash", "Card", "M-Pesa"])
      }
    end)
    |> Enum.sort_by(fn p -> p.date end, {:desc, Date})
  end

  defp generate_loyalty_history(customer) do
    Enum.map(1..5, fn i ->
      days_ago = :rand.uniform(180)
      date = DateTime.add(DateTime.utc_now(), -days_ago * 24 * 3600, :second)
      is_credit = :rand.uniform(100) <= 80
      points = if is_credit, do: :rand.uniform(300) + 50, else: -(:rand.uniform(200) + 100)

      reason =
        if is_credit do
          "Purchase: Receipt #S#{10000 + :rand.uniform(999)}"
        else
          "Redemption: #{Enum.random(["Discount coupon", "Free product"])}"
        end

      %{
        id: i,
        date: date,
        points: points,
        reason: reason,
        type: if(is_credit, do: "credit", else: "debit")
      }
    end)
    |> Enum.sort_by(fn h -> h.date end, {:desc, DateTime})
  end

  defp membership_level_color(level) do
    case level do
      "Bronze" -> "bg-amber-700"
      "Silver" -> "bg-gray-500"
      "Gold" -> "bg-yellow-500"
      "Platinum" -> "bg-blue-700"
      _ -> "bg-gray-700"
    end
  end

  defp tier_border_color(level) do
    case level do
      "Bronze" -> "border-amber-300"
      "Silver" -> "border-gray-300"
      "Gold" -> "border-yellow-300"
      "Platinum" -> "border-blue-300"
      _ -> "border-gray-300"
    end
  end

  defp current_membership_tier(points, tiers) do
    Enum.reduce(tiers, List.first(tiers), fn tier, acc ->
      if points >= tier.min_points && tier.min_points >= acc.min_points, do: tier, else: acc
    end)
  end

  defp next_membership_tier(points, tiers) do
    sorted_tiers = Enum.sort_by(tiers, & &1.min_points)
    Enum.find(sorted_tiers, fn tier -> tier.min_points > points end)
  end

  defp calculate_progress_percentage(points, current_min, next_min) do
    range = next_min - current_min
    progress = points - current_min
    percentage = progress / range * 100
    min(max(percentage, 0), 100)
  end

  defp format_currency(amount) when is_nil(amount), do: "KSh 0.00"

  defp format_currency(%Decimal{} = amount) do
    "KSh #{:erlang.float_to_binary(Decimal.to_float(amount), decimals: 2)}"
  end

  defp format_currency(amount) when is_float(amount) do
    "KSh #{:erlang.float_to_binary(amount, decimals: 2)}"
  end

  defp format_currency(amount) when is_integer(amount) do
    "KSh #{:erlang.float_to_binary(amount / 1, decimals: 2)}"
  end

  defp format_currency(_), do: "KSh 0.00"
end
