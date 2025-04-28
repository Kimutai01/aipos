defmodule Aipos.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :name, :string
      add :phone, :string
      add :email, :string
      add :address, :text
      add :loyalty_points, :integer
      add :membership_level, :string
      add :total_spent, :decimal
      add :total_orders, :integer
      add :days_since_last_purchase, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
