defmodule AiposWeb.IotController do
  use AiposWeb, :controller

  plug :accepts, ["json"]

  def create_card(conn, params) do
    case Aipos.Cards.create_card(params) do
      {:ok, card} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{card: card}))

      {:error, %Ecto.Changeset{} = changeset} ->
        formatted_errors = format_errors(changeset)

        conn
        |> put_status(:unprocessable_entity)
        |> put_resp_content_type("application/json")
        |> send_resp(422, Jason.encode!(%{errors: formatted_errors}))
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def get_product_status(conn, params) do
    IO.inspect(params, label: "Params")
    product_sku = Aipos.ProductSkus.get_product_sku_by_card(params["card"])
    IO.inspect(product_sku, label: "Product SKU")

    if product_sku do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{product_sku: product_sku}))
    else
      conn
      |> put_status(:not_found)
      |> put_resp_content_type("application/json")
      |> send_resp(404, Jason.encode!(%{error: "Product not found"}))
    end
  end
end
