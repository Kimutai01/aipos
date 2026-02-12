defmodule Aipos.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :address, :string
    field :email, :string
    field :logo, :string
    field :name, :string
    field :phone, :string
    field :description, :string
    field :kra_pin, :string
    field :location, :string
    belongs_to :created_by, Aipos.Accounts.User, foreign_key: :created_by_id
    has_many :users, Aipos.Accounts.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :address, :phone, :email, :logo, :description, :kra_pin, :location, :created_by_id])
    |> validate_required([:name, :address, :phone, :email, :kra_pin])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_format(:kra_pin, ~r/^P\d{9}[A-Z]$/, message: "must be a valid KRA PIN (e.g., P051234567A)")
  end
end
