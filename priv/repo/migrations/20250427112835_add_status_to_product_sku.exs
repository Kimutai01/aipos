defmodule Aipos.Repo.Migrations.AddStatusToProductSku do
  use Ecto.Migration

  def change do
    alter table(:product_skus) do
      add :status, :string, default: "not_sold"
    end
  end
end
