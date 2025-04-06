defmodule Aipos.RegistersTest do
  use Aipos.DataCase

  alias Aipos.Registers

  describe "registers" do
    alias Aipos.Registers.Register

    import Aipos.RegistersFixtures

    @invalid_attrs %{name: nil, status: nil}

    test "list_registers/0 returns all registers" do
      register = register_fixture()
      assert Registers.list_registers() == [register]
    end

    test "get_register!/1 returns the register with given id" do
      register = register_fixture()
      assert Registers.get_register!(register.id) == register
    end

    test "create_register/1 with valid data creates a register" do
      valid_attrs = %{name: "some name", status: "some status"}

      assert {:ok, %Register{} = register} = Registers.create_register(valid_attrs)
      assert register.name == "some name"
      assert register.status == "some status"
    end

    test "create_register/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Registers.create_register(@invalid_attrs)
    end

    test "update_register/2 with valid data updates the register" do
      register = register_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status"}

      assert {:ok, %Register{} = register} = Registers.update_register(register, update_attrs)
      assert register.name == "some updated name"
      assert register.status == "some updated status"
    end

    test "update_register/2 with invalid data returns error changeset" do
      register = register_fixture()
      assert {:error, %Ecto.Changeset{}} = Registers.update_register(register, @invalid_attrs)
      assert register == Registers.get_register!(register.id)
    end

    test "delete_register/1 deletes the register" do
      register = register_fixture()
      assert {:ok, %Register{}} = Registers.delete_register(register)
      assert_raise Ecto.NoResultsError, fn -> Registers.get_register!(register.id) end
    end

    test "change_register/1 returns a register changeset" do
      register = register_fixture()
      assert %Ecto.Changeset{} = Registers.change_register(register)
    end
  end
end
