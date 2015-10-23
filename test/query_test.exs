defmodule ExAdminTest.ExAdmin.Blog do
  use ExAdmin.Register
  register_resource ExAdminTest.Blog do
  end
end

defmodule ExAdmin.QueryTest do
  use ExUnit.Case
  import Ecto.Query

  alias ExAdmin.Query
  
  defmodule Repo do
    def all(query), do: query
    def paginate(query, opts), do: {query, opts}
  end

  test "first" do
    resource_model = %ExAdminTest.ExAdmin.Blog{} |> Map.get(:resource_model)
    {result, _} = Query.run_query(resource_model, Repo, :index, [resource: :blog], %{all: [preload: [:user]]}) 
    preload = [:user]
    q = from c in ExAdminTest.Blog, order_by: [desc: c.id], preload: ^preload
    assert inspect(result) == inspect(q)
  end

end
