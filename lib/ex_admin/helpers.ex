Code.ensure_compiled(ExAdmin.Utils)

defmodule ExAdmin.Helpers do
  @moduledoc false
  require Logger
  require Integer
  use Xain
  import Kernel, except: [to_string: 1]
  import ExAdmin.Utils
  import ExAdmin.Render

  def build_fieldset_legend(nil), do: []
  def build_fieldset_legend(""), do: []

  def build_fieldset_legend(name) do
    [
      legend ".inputs" do
        span(name)
      end
    ]
  end

  def build_link(nil, _, _, _, _), do: ""
  def build_link("", _, _, _, _), do: ""
  def build_link(contents, _conn, %{link: false}, _resource, _field_name), do: contents

  def build_link(contents, conn, _, resource, field_name) do
    case Map.get(resource, field_name) do
      nil ->
        contents

      res when is_map(res) ->
        if ExAdmin.Utils.authorized_action?(conn, :index, res.__struct__) do
          path = admin_resource_path(res, :index)
          "<a href='#{path}'>#{contents}</a>"
        else
          contents
        end
    end
  end

  def model_name(%{__struct__: name}), do: model_name(name)

  def model_name(resource) when is_atom(resource) do
    if has_function?(resource, :model_name, 0) do
      resource.model_name()
    else
      resource |> ExAdmin.Utils.base_name() |> Inflex.underscore()
    end
  end

  def build_link_for({:safe, _} = safe_contents, d, a, b, c) do
    safe_contents
    |> Phoenix.HTML.safe_to_string()
    |> build_link_for(d, a, b, c)
  end

  def build_link_for("", _, _, _, _), do: ""
  def build_link_for(nil, _, _, _, _), do: ""
  def build_link_for(contents, _, %{link: false}, _, _), do: contents

  def build_link_for(contents, conn, opts, resource, field_name) do
    case Map.get(resource, field_name) do
      nil ->
        contents

      %{__meta__: _} = res ->
        build_content_link(true, conn, res, contents)

      _ ->
        build_content_link(opts[:link], conn, resource, contents)
    end
  end

  defp build_content_link(link?, conn, resource, contents) do
    if link? && ExAdmin.Utils.authorized_action?(conn, :show, resource) do
      path = admin_resource_path(resource, :show)
      "<a href='#{path}'>#{contents}</a>"
    else
      contents
    end
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

  def map_relationship_fields(resource, fields, separator \\ " ")
  def map_relationship_fields(nil, _fields, _separator), do: ""

  def map_relationship_fields(resource, fields, separator) do
    Enum.map(fields, &get_resource_field(resource, &1))
    |> Enum.join(separator)
  end

  def get_association_fields(%{fields: fields}), do: fields
  def get_association_fields(%{}), do: [:name]

  def get_association_owner_key(resource, association) when is_binary(association),
    do: get_association_owner_key(resource, String.to_atom(association))

  def get_association_owner_key(resource, association) do
    resource.__struct__.__schema__(:association, association).owner_key
  end

  defp get_field_type(%{__struct__: resource_struct, __meta__: _}, field) do
    resource_struct.__schema__(:type, field)
  end

  defp get_field_type(_resource, _field), do: nil

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
        f_name =
          case get_field_type(resource, f_name) do
            nil -> f_name
            type -> {type, f_name}
          end

        build_single_field(resource, conn, f_name, opts)
        |> fun.(f_name)

      {f_name, []} ->
        build_single_field(resource, conn, f_name, %{})
        |> fun.(f_name)

      _ ->
        fun.("", :none)
    end
  end

  def build_single_field(resource, conn, {_, f_name}, opts) do
    build_single_field(resource, conn, f_name, opts)
  end

  def build_single_field(resource, conn, f_name, %{fun: fun, image: true} = opts) do
    attributes =
      opts
      |> Map.delete(:fun)
      |> Map.delete(:image)
      |> build_attributes

    "<img src='#{fun.(resource)}'#{attributes} />"
    |> build_link_for(conn, opts, resource, f_name)
  end

  def build_single_field(resource, conn, f_name, %{toggle: true}) do
    build_single_field(resource, conn, f_name, %{toggle: ~w(YES NO)})
  end

  def build_single_field(resource, _conn, f_name, %{toggle: [yes, no]}) do
    path = fn attr_value ->
      admin_resource_path(resource, :toggle_attr, [[attr_name: f_name, attr_value: attr_value]])
    end

    current_value = Map.get(resource, f_name)

    [yes_btn_css, no_btn_css] =
      case current_value do
        true ->
          ["btn-primary", "btn-default"]

        false ->
          ["btn-default", "btn-primary"]

        value ->
          raise ArgumentError.exception(
                  "`toggle` option could be used only with columns of boolean type.\nBut `#{
                    f_name
                  }` is #{inspect(IEx.Info.info(value))}\nwith value == #{inspect(value)}"
                )
      end

    [
      ~s(<a id="#{f_name}_true_#{resource.id}" class="toggle btn btn-sm #{yes_btn_css}" href="#{
        path.(true)
      }" data-remote="true" data-method="put" #{if !!current_value, do: "disabled"}>#{yes}</a>),
      ~s(<a id="#{f_name}_false_#{resource.id}" class="toggle btn btn-sm #{no_btn_css}" href="#{
        path.(false)
      }" data-remote="true" data-method="put" #{if !current_value, do: "disabled"}>#{no}</a>)
    ]
    |> Enum.join()
  end

  def build_single_field(resource, conn, f_name, %{fun: fun} = opts) do
    markup :nested do
      case fun.(resource) do
        [{_, list}] -> list
        other -> other
      end
    end
    |> build_link_for(conn, opts, resource, f_name)
  end

  def build_single_field(%{__struct__: resource_struct} = resource, conn, f_name, opts) do
    resource_struct.__schema__(:type, f_name)
    |> build_single_field_type(resource, conn, f_name, opts)
  end

  def build_single_field(%{} = resource, conn, f_name, opts) do
    build_single_field_type(:array_map, resource, conn, f_name, opts)
  end

  defp build_single_field_type({:array, type}, resource, conn, f_name, opts)
       when type in [:string, :integer] do
    case get_resource_field(resource, f_name, opts) do
      list when is_list(list) ->
        Enum.map(list, &to_string(&1))
        |> Enum.join(", ")

      other ->
        to_string(other)
    end
    |> build_link_for(conn, opts, resource, f_name)
  end

  defp build_single_field_type(:array_map, resource, conn, f_name, opts) do
    Map.get(resource, to_string(f_name), "")
    |> build_link_for(conn, opts, resource, f_name)
  end

  defp build_single_field_type(_, resource, conn, f_name, opts) do
    get_resource_field(resource, f_name, opts)
    |> format_contents
    |> build_link_for(conn, opts, resource, f_name)
  end

  defp format_contents(contents) when is_list(contents) do
    contents
    |> Enum.map(&format_contents/1)
    |> to_string
  end

  defp format_contents(%{__struct__: _} = contents), do: to_string(contents)

  defp format_contents(%{} = contents) do
    Enum.reduce(contents, [], fn {k, v}, acc ->
      value = ExAdmin.Render.to_string(v)
      ["#{k}: #{value}" | acc]
    end)
    |> Enum.reverse()
    |> Enum.join(", ")
  end

  defp format_contents(contents), do: to_string(contents)

  def get_resource_model(resources) do
    case resources do
      [] ->
        ""

      [resource | _] ->
        get_resource_model(resource)

      %{__struct__: name} ->
        name |> base_name |> Inflex.underscore()

      %{} ->
        :map
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
      nil -> []
      %Ecto.Association.NotLoaded{} -> []
      other -> other
    end
  end

  def get_resource_field(resource, field, opts \\ %{}) when is_map(resource) do
    opts = Enum.into(opts, %{})

    case resource do
      %{__struct__: struct_name} ->
        cond do
          field in struct_name.__schema__(:fields) ->
            Map.get(resource, field)

          field in struct_name.__schema__(:associations) ->
            get_relationship(resource, field)
            |> map_relationship_fields(get_association_fields(opts))

          has_function?(struct_name, field, 1) ->
            try_function(struct_name, resource, field, fn _error ->
              raise ExAdmin.RuntimeError,
                message: "Could not call resource function #{:field} on #{struct_name}"
            end)

          function_exported?(
            ExAdmin.get_registered(resource.__struct__).__struct__,
            :display_name,
            1
          ) ->
            apply(ExAdmin.get_registered(resource.__struct__).__struct__, :display_name, [
              resource
            ])

          function_exported?(resource.__struct__, :display_name, 1) ->
            apply(resource.__struct__, :display_name, [resource])

          true ->
            case resource.__struct__.__schema__(:fields) do
              [_, first | _] ->
                Map.get(resource, first)

              [id | _] ->
                Map.get(resource, id)

              _ ->
                raise ExAdmin.RuntimeError,
                  message: "Could not find field #{inspect(field)} in #{inspect(resource)}"
            end
        end

      _ ->
        raise ExAdmin.RuntimeError, message: "Resource must be a struct"
    end
  end

  def get_name_field(resource_model) do
    fields = resource_model.__schema__(:fields)
    name_field = fields |> Enum.find(fn field -> field == :name || field == :title end)

    if name_field do
      name_field
    else
      fields |> Enum.find(fn field -> resource_model.__schema__(:type, field) == :string end)
    end
  end

  def display_name(resource) do
    defn = ExAdmin.get_registered(resource.__struct__)

    cond do
      is_nil(defn) ->
        get_name_column_field(resource)

      function_exported?(defn.__struct__, :display_name, 1) ->
        apply(defn.__struct__, :display_name, [resource])

      function_exported?(resource.__struct__, :display_name, 1) ->
        apply(resource.__struct__, :display_name, [resource])

      true ->
        case defn.name_column do
          nil -> get_name_column_field(resource)
          name_field -> resource |> Map.get(name_field) |> to_string
        end
    end
  end

  defp get_name_column_field(resource) do
    case get_name_field(resource.__struct__) do
      nil -> inspect(resource)
      field -> Map.get(resource, field)
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

      name ->
        name
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
    :os.timestamp() |> Tuple.to_list() |> Enum.join() |> String.to_integer()
  end

  def group_by(collection, fun) do
    list =
      Enum.map(collection, fun)
      |> Enum.uniq_by(& &1)
      |> Enum.map(&{&1, []})

    Enum.reduce(collection, list, fn item, acc ->
      key = fun.(item)
      {_, val} = List.keyfind(acc, key, 0)
      List.keyreplace(acc, key, 0, {key, val ++ [item]})
    end)
  end

  def group_reduce_by_reverse(collection) do
    empty =
      Keyword.keys(collection)
      |> Enum.reduce([], &Keyword.put(&2, &1, []))

    Enum.reduce(collection, empty, fn {k, v}, acc ->
      Keyword.put(acc, k, [v | acc[k]])
    end)
  end

  def group_reduce_by(collection) do
    group_reduce_by_reverse(collection)
    |> Enum.reduce([], fn {k, v}, acc ->
      Keyword.put(acc, k, Enum.reverse(v))
    end)
  end

  def to_class(prefix, field_name), do: prefix <> to_class(field_name)

  def to_class({_, field_name}), do: to_class(field_name)

  def to_class(field_name) when is_binary(field_name),
    do: field_name_to_class(Inflex.parameterize(field_name, "_"))

  def to_class(field_name) when is_atom(field_name),
    do: field_name_to_class(Atom.to_string(field_name))

  def build_attributes(%{} = opts) do
    build_attributes(Map.to_list(opts))
  end

  def build_attributes(opts) do
    Enum.reduce(opts, "", fn {k, v}, acc ->
      acc <> " #{k}='#{v}'"
    end)
  end

  def translate_field(defn, field) do
    case Regex.scan(~r/(.+)_id$/, Atom.to_string(field)) do
      [[_, assoc]] ->
        assoc = String.to_atom(assoc)
        if assoc in defn.resource_model.__schema__(:associations), do: assoc, else: field

      _ ->
        case defn.resource_model.__schema__(:type, field) do
          :map -> {:map, field}
          {:array, :map} -> {:maps, field}
          _ -> field
        end
    end
  end

  def field_name_to_class(field_name) do
    parameterize(String.replace_suffix(field_name, "?", ""))
  end
end
