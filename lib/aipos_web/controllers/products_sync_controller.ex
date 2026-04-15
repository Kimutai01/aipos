defmodule AiposWeb.ProductsSyncController do
  use AiposWeb, :controller

  alias Aipos.ProductSkus
  import Ecto.Query

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    org_id = current_user.organization_id

    skus =
      if org_id do
        Aipos.Repo.all(
          from s in Aipos.ProductSkus.ProductSku,
            where: s.organization_id == ^org_id and s.stock_quantity > 0,
            select: %{
              id: s.id,
              name: s.name,
              barcode: s.barcode,
              price: s.price,
              stock_quantity: s.stock_quantity
            }
        )
      else
        []
      end

    json(conn, %{products: Enum.map(skus, fn s ->
      %{
        id: s.id,
        name: s.name,
        barcode: s.barcode,
        price: if(s.price, do: Decimal.to_string(s.price), else: "0"),
        stock_quantity: s.stock_quantity
      }
    end)})
  end
end
