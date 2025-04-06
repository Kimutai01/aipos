defmodule Aipos.Repo.Migrations.CreateProductSkus do
  use Ecto.Migration

  def change do
    create table(:product_skus) do
      add :name, :string
      add :description, :string
      add :image, :string
      add :barcode, :string
      add :price, :decimal
      add :cost, :decimal
      add :stock_quantity, :integer
      add :buffer_level, :integer
      add :rfid_tag, :string
      add :product_id, references(:products, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:product_skus, [:product_id])
  end
end
