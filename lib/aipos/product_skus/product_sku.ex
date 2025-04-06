defmodule Aipos.ProductSkus.ProductSku do
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_skus" do
    field :barcode, :string
    field :buffer_level, :integer
    field :cost, :decimal
    field :description, :string
    field :image, :string
    field :name, :string
    field :price, :decimal
    field :rfid_tag, :string
    field :stock_quantity, :integer
    belongs_to :product, Aipos.Products.Product
    timestamps(type: :utc_datetime)
    field :temp_id, :string, virtual: true
    field :delete, :boolean, virtual: true
    belongs_to :organization, Aipos.Organizations.Organization
    belongs_to :user, Aipos.Users.User
  end

  @doc false
  def changeset(product_sku, attrs) do
    product_sku
    |> Map.put(:temp_id, product_sku.temp_id || attrs["temp_id"])
    |> cast(attrs, [
      :name,
      :description,
      :product_id,
      :image,
      :barcode,
      :price,
      :cost,
      :stock_quantity,
      :buffer_level,
      :rfid_tag,
      :organization_id,
      :user_id,
      :temp_id,
      :delete
    ])
    |> validate_required([:name])
    |> foreign_key_constraint(:product_id)
    |> unique_constraint(:barcode, message: "has already been registered")
    |> maybe_mark_for_deletion()
  end

  defp maybe_mark_for_deletion(%{data: %{id: nil}} = changeset), do: changeset

  defp maybe_mark_for_deletion(changeset) do
    if get_change(changeset, :delete) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
