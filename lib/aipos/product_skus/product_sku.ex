defmodule Aipos.ProductSkus.ProductSku do
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_skus" do
    field :barcode, :string
    field :buffer_level, :string
    field :cost, :string
    field :description, :string
    field :image, :string
    field :name, :string
    field :price, :string
    field :rfid_tag, :string
    field :stock_quantity, :string
    field :product_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product_sku, attrs) do
    product_sku
    |> cast(attrs, [:name, :description, :image, :barcode, :price, :cost, :stock_quantity, :buffer_level, :rfid_tag])
    |> validate_required([:name, :description, :image, :barcode, :price, :cost, :stock_quantity, :buffer_level, :rfid_tag])
  end
end
