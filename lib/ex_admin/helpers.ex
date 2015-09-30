Code.ensure_compiled(ExAdmin.Utils)
defmodule ExAdmin.Helpers do
  require Logger
  require Integer
  use Xain
  import ExAdmin.Utils

  def csrf_token(conn) do
    Map.get conn.req_cookies, "_csrf_token"
  end

  def build_fieldset_legend(nil), do: []
  def build_fieldset_legend(""), do: []
  def build_fieldset_legend(name) do
    [
      legend(".inputs") do
        span(name)
      end
    ]
  end

  def build_link(nil, _, _, _, _), do: ""
  def build_link("", _, _, _, _), do: ""
  def build_link(contents, _conn, %{link: false}, _resource, _field_name), do: contents
  def build_link(contents, conn, _, resource, field_name) do
    case Map.get(resource, field_name) do
      nil -> contents
      res when is_map(res) -> 
        if ExAdmin.Utils.authorized_action? conn, :index, res.__struct__ do
          path = get_route_path res, :index
          "<a href='#{path}'>#{contents}</a>"
        else
          contents
        end
    end
  end

  def model_name(resource) when is_atom(resource) do
    resource |> ExAdmin.Utils.base_name |> Inflex.parameterize("_")
  end
  def model_name(%{__struct__: name}) do
    model_name name
  end

  def build_link_for({:safe, contents}, d, a, b, c) when is_list(contents) do 
    safe_contents("", contents)
    |> build_link_for(d, a, b, c)
  end
  def build_link_for({:safe, contents}, d, a, b, c), do: build_link_for(contents, d, a, b, c)
  def build_link_for("", _, _, _, _), do: ""
  def build_link_for(nil, _, _, _, _), do: ""
  def build_link_for(contents, _, %{link: false}, _, _), do: contents
  def build_link_for(contents, conn, _, resource, field_name) do
    # id  = resource.id
    case Map.get resource, field_name do
      nil -> contents
      res when is_map(res) -> 
        if ExAdmin.Utils.authorized_action? conn, :show, res.__struct__ do
          path = get_route_path res, :show, res.id
          "<a href='#{path}'>#{contents}</a>"
        else
          contents
        end
      _ -> contents
    end
  end
  

  def safe_contents(acc, []), do: acc
  def safe_contents(acc, [h|t]) when is_list(h) do
    safe_contents(acc, h)
    |> safe_contents(t)
  end
  def safe_contents(acc, [h|t]) when is_binary(h) do
    safe_contents(acc <> h, t)
  end

  def build_header_field(field, fun) do
    case field do
      {f_name, _} -> f_name
      f_name -> f_name
    end
    |> fun.()
  end

  def get_relationship(resource, field_name) do
    Map.get(resource, field_name, %{}) 
  end

  def map_relationship_fields(resource,fields, separator \\ " ")
  def map_relationship_fields(nil, _fields, _separator), do: ""
  def map_relationship_fields(resource, fields, separator) do

    Enum.map(fields, &(get_resource_field(resource, &1)))
    |> Enum.join(separator)
  end

  def get_association_fields(%{fields: fields}), do: fields
  def get_association_fields(%{}), do: [:name]

  def get_association_owner_key(resource, association) when is_binary(association), 
    do: get_association_owner_key(resource, String.to_atom(association))
  def get_association_owner_key(resource, association) do
    Logger.warn "association: #{inspect association}"
    resource.__struct__.__schema__(:association, association).owner_key
  end


  @doc """
  Builds a web field.

  Handles parsing relationships, linking to the relationship, passing a 
  concatenated string of each of the given fields.
  """
  def build_field(resource, conn, field_name, fun) do
    case field_name do

      {f_name, %{has_many: _} = map2} -> 
        _build_field(map2, conn, resource, f_name)
        |> fun.(f_name)

      {f_name, %{} = opts} -> 
        build_single_field(resource, conn, f_name, opts)
        |> fun.(f_name)

      {f_name, []} -> 
        build_single_field(resource, conn, f_name, %{})
        |> fun.(f_name)

      _ -> 
        fun.("", :none)
    end
  end

  def build_single_field(resource, conn, f_name, %{fun: fun} = opts) do
    fun.(resource)
    |> build_link_for(conn, opts, resource, f_name)
  end 

  def build_single_field(resource, conn, f_name, opts) do
    case get_resource_field(resource, f_name, opts) do
      nil -> 
        ""
      other when is_binary(other) -> 
        other
      integer when is_integer(integer) -> 
        "#{integer}"

      %Ecto.DateTime{} = datetime -> 
        Ecto.DateTime.to_string datetime

      other -> 
        "#{inspect other}"
    end
    |> build_link_for(conn, opts, resource, f_name)
  end
  
  def get_resource_model(resources) do
    case resources do
      [] -> 
        ""
      [resource | _] -> 
        get_resource_model resource

      %{__struct__: name} -> 
        name |> base_name |>  Inflex.parameterize("_")
    end
  end
  defp _build_field(%{fields: fields} = map, conn, resource, field_name) do
    get_relationship(resource, field_name)
    |> map_relationship_fields(fields)
    |> build_link(conn, map, resource, field_name)
  end
  defp _build_field(%{}, _, _resource, _field_name), do: []

  def get_resource_field2(resource, field_name) do
    case Map.get(resource, field_name) do
      %Ecto.Association.NotLoaded{} -> []
      other -> other
    end
  end
  
  def get_resource_field(resource, field, opts \\ %{}) when is_map(resource) do
    opts = Enum.into opts, %{}
    #IO.puts "---> get_resource_field field: #{inspect field}, resource: #{inspect resource}"
    case resource do
      %{__struct__: struct_name} ->
        cond do
          field in struct_name.__schema__(:fields) -> 
            Map.get(resource, field)
          field in struct_name.__schema__(:associations) -> 
            get_relationship(resource, field)
            |> map_relationship_fields(get_association_fields(opts))
          has_function?(struct_name, field, 1) -> 
            try_function struct_name, resource, field, fn(_error) -> 
              raise ExAdmin.RuntimeError, 
                message: "Could not call resource function #{:field} on #{struct_name}"
            end
          true -> 
            raise ExAdmin.RuntimeError, message: "Could not find field #{inspect field} in #{inspect resource}"
        end
      _ -> 
        raise ExAdmin.RuntimeError, message: "Resource must be a struct"
    end
  end

  def resource_identity(resource, field \\ :name)
  def resource_identity(resource, field) when is_map(resource) do
    case Map.get(resource, field) do
      nil -> 
        case resource do
          %{__struct__: struct_name} -> 
            if {field, 1} in struct_name.__info__(:functions) do
              try do
                apply(struct_name, field, [resource])
              rescue 
                _ -> 
                  struct_name |> base_name |> titleize
              end
            else
              struct_name |> base_name |> titleize
            end
          _ -> 
            ""
        end
      name -> name
    end
  end
  def resource_identity(_, _), do: ""

  def has_function?(struct_name, function, arity) do
    {function, arity} in struct_name.__info__(:functions)
  end

  def try_function(struct_name, resource, function, rescue_fun \\ nil) do
    try do
      apply(struct_name, function, [resource])
    rescue 
      error -> 
        if rescue_fun, do: rescue_fun.(error)
    end
  end

  def timestamp do
    :os.timestamp |> Tuple.to_list |> Enum.join |>  String.to_integer
  end

  def group_by(collection, fun) do
    list = Enum.map(collection, fun)
    |> Enum.uniq(&(&1))
    |> Enum.map(&({&1, []}))
    
    Enum.reduce collection, list, fn(item, acc) -> 
      key = fun.(item)
      {_, val} = List.keyfind acc, key, 0
      List.keyreplace acc, key, 0, {key, val ++ [item]}
    end
  end

  def to_class(field_name) when is_binary(field_name), 
    do: Inflex.parameterize(field_name, "_")
  def to_class(field_name) when is_atom(field_name), 
    do: Atom.to_string(field_name)

  def get_sort_order(nil), do: nil
  def get_sort_order(order) do
    case Regex.scan ~r/(.+)_(desc|asc)$/, order do
      [] -> nil
      [[_, name, sort_order]] -> {name, sort_order}
    end
  end
end
