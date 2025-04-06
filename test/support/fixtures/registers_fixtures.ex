defmodule Aipos.RegistersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aipos.Registers` context.
  """

  @doc """
  Generate a register.
  """
  def register_fixture(attrs \\ %{}) do
    {:ok, register} =
      attrs
      |> Enum.into(%{
        name: "some name",
        status: "some status"
      })
      |> Aipos.Registers.create_register()

    register
  end
end
