defmodule AiposWeb.SaleSyncController do
  use AiposWeb, :controller

  alias Aipos.Sales
  alias Aipos.ProductSkus

  def sync(conn, %{"sale" => sale_params}) do
    current_user = conn.assigns.current_user
    cart_items = sale_params["cart_items"] || []

    if Enum.empty?(cart_items) do
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: "No items in sale"})
    else
      total_amount =
        Enum.reduce(cart_items, Decimal.new(0), fn item, acc ->
          Decimal.add(acc, parse_decimal(item["subtotal"]))
        end)

      amount_tendered = parse_decimal(sale_params["amount_tendered"])

      change_due =
        case Decimal.compare(amount_tendered, total_amount) do
          :lt -> Decimal.new(0)
          _ -> Decimal.sub(amount_tendered, total_amount)
        end

      sale_attrs = %{
        register_id: sale_params["register_id"],
        cashier_id: current_user.id,
        total_amount: total_amount,
        payment_method: "cash",
        amount_tendered: amount_tendered,
        change_due: change_due,
        status: "completed",
        organization_id: current_user.organization_id
      }

      case Sales.create_sale(sale_attrs) do
        {:ok, sale} ->
          Enum.each(cart_items, fn item ->
            item_attrs = %{
              sale_id: sale.id,
              product_sku_id: item["sku_id"],
              name: item["name"],
              quantity: item["quantity"],
              price: parse_decimal(item["price"]),
              subtotal: parse_decimal(item["subtotal"]),
              organization_id: current_user.organization_id
            }

            {:ok, _} = Sales.create_sale_item(item_attrs)
            deduct_stock(item["sku_id"], item["quantity"])
          end)

          json(conn, %{ok: true, sale_id: sale.id})

        {:error, changeset} ->
          errors = format_errors(changeset)

          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: errors})
      end
    end
  end

  defp parse_decimal(val) when is_binary(val) do
    case Decimal.parse(val) do
      {d, _} -> d
      :error -> Decimal.new(0)
    end
  end

  defp parse_decimal(val) when is_float(val), do: Decimal.from_float(val)
  defp parse_decimal(val) when is_integer(val), do: Decimal.new(val)
  defp parse_decimal(_), do: Decimal.new(0)

  defp deduct_stock(sku_id, quantity) when is_binary(sku_id),
    do: deduct_stock(String.to_integer(sku_id), quantity)

  defp deduct_stock(sku_id, quantity) do
    try do
      sku = ProductSkus.get_product_sku!(sku_id)
      new_qty = max(0, sku.stock_quantity - quantity)
      ProductSkus.update_product_sku(sku, %{stock_quantity: new_qty})
    rescue
      _ -> :ok
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> inspect()
  end
end
