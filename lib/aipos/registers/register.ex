defmodule Aipos.Registers.Register do
  use Ecto.Schema
  import Ecto.Changeset

  schema "registers" do
    field :name, :string
    field :status, :string, default: "available"
    field :last_used_at, :utc_datetime
    belongs_to :organization, Aipos.Organizations.Organization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(register, attrs) do
    register
    |> cast(attrs, [:name, :status, :organization_id, :last_used_at])
    |> validate_required([:name, :organization_id])
    |> validate_inclusion(:status, ["available", "in_use"])
    |> foreign_key_constraint(:organization_id)
  end
end
