defmodule Aipos.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :address, :string
    field :days_since_last_purchase, :integer
    field :email, :string
    field :loyalty_points, :integer
    field :membership_level, :string
    field :name, :string
    field :phone, :string
    field :total_orders, :integer
    field :total_spent, :decimal

    belongs_to :organization, Aipos.Organizations.Organization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [
      :name,
      :phone,
      :email,
      :address,
      :loyalty_points,
      :membership_level,
      :total_spent,
      :total_orders,
      :organization_id,
      :days_since_last_purchase
    ])
    |> validate_required([
      :name,
      :phone,
      :email,
      :address,
      :loyalty_points,
      :membership_level,
      :total_spent,
      :total_orders,
      :days_since_last_purchase
    ])
  end
end
