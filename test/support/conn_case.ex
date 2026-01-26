defmodule DeadSimpleCmsWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DeadSimpleCmsWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint DeadSimpleCmsWeb.Endpoint

      use DeadSimpleCmsWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import DeadSimpleCmsWeb.ConnCase
      import DeadSimpleCms.Factory
    end
  end

  setup tags do
    DeadSimpleCms.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that provides only base data.

      setup :base_data

  It stores an updated connection and a base_data in the
  test context.
  """
  def base_data(%{conn: conn}) do
    data = DeadSimpleCms.Factory.base_setup()

    %{conn: conn, data: data}
  end
end
