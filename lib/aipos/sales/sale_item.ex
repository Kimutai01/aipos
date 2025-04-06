defmodule Aipos.Sales.SaleItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sale_items" do
    field :name, :string
    field :price, :decimal
    field :quantity, :integer
    field :subtotal, :decimal

    belongs_to :sale, Aipos.Sales.Sale
    belongs_to :product_sku, Aipos.ProductSkus.ProductSku
    belongs_to :organization, Aipos.Organizations.Organization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sale_item, attrs) do
    sale_item
    |> cast(attrs, [
      :name,
      :quantity,
      :price,
      :subtotal,
      :sale_id,
      :product_sku_id,
      :organization_id
    ])
    |> validate_required([:name, :quantity, :price, :subtotal])
  end
end
