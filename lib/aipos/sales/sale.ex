defmodule Aipos.Sales.Sale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sales" do
    field :amount_tendered, :decimal
    field :change_due, :decimal
    field :payment_method, :string
    field :status, :string
    field :total_amount, :decimal
    # field :register_id, :id
    # field :cashier_id, :id
    field :customer_id, :id
    # field :organization_id, :id
    belongs_to :register, Aipos.Registers.Register
    belongs_to :cashier, Aipos.Users.User
    belongs_to :organization, Aipos.Organizations.Organization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sale, attrs) do
    sale
    |> cast(attrs, [
      :total_amount,
      :payment_method,
      :amount_tendered,
      :change_due,
      :status,
      :register_id,
      :cashier_id,
      # :customer_id,
      :organization_id
    ])
    |> validate_required([:total_amount, :payment_method, :amount_tendered, :change_due, :status])
  end
end
