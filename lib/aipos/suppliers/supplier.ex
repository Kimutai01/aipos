defmodule Aipos.Suppliers.Supplier do
  use Ecto.Schema
  import Ecto.Changeset

  schema "suppliers" do
    field :address, :string
    field :contact_name, :string
    field :email, :string
    field :last_order_date, :date
    field :lead_time, :integer
    field :name, :string
    field :notes, :string
    field :payment_terms, :string
    field :phone, :string
    field :status, :string
    field :tags, {:array, :string}

    belongs_to :organization, Aipos.Organizations.Organization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(supplier, attrs) do
    supplier
    |> cast(attrs, [
      :name,
      :contact_name,
      :phone,
      :email,
      :address,
      :tags,
      :status,
      :payment_terms,
      :lead_time,
      :last_order_date,
      :notes,
      :organization_id
    ])
    |> validate_required([
      :name,
      :contact_name,
      :phone,
      :email,
      :address,
      :status,
      :payment_terms
    ])
  end
end
