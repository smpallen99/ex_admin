defmodule ExAdmin.Index do
  @moduledoc """
  Override the default index page for an ExAdmin resource

  By default, ExAdmin renders the index table without any additional 
  configuration. It renders each column in the model, except the id, 
  inserted_at, and updated_at columns. 

  ## Default Table Type

  ExAdmin displays a selection checkbox column on the left with a batch
  action control that enables when a checkbox is selected. 

  To customize the index page, use the `index` macro. 

  For example, the following will show on the id an name fields, as 
  well place a selection column and batch actions row on the page:

      defmodule MyProject.ExAdmin.MyModel do
        use ExAdmin.Register
        register_resource MyProject.MyModel do

          index do 
            selectable_column

            column :id
            column :name
          end
        end
      end

  ### Image fields

  For image fields, use the `image: true` option. For example:

      index do 
        column :name
        column :image, [image: true, height: 100], &(ExAdminDemo.Image.url({&1.image, &1}, :thumb))
      end

  ### Custom columns

  Columns can be customized with column/2 where the second argument is
  an anonymous function called with model. Here are a couple examples:

      index do 
        column :id 
        column :name, fn(category) -> 
          Phoenix.HTML.Tag.content_tag :span, category.name, 
            "data-id": category.id, class: "category"
        end
        column "Created", fn(category) -> 
          category.created_at
        end
      end

  ### Override the Actions column

  The Actions column can be customized by adding `column "Actions", fn(x) -> ...`

      column "Actions", fn(r) -> 
        safe_concat link_to("Restore", "/admin/backuprestores/restore/#\{r.id}", "data-method": :put, 
            "data-confirm": "You are about to restore #\{r.file_name}. Are you sure?",
            class: "member_link restore-link"), 
          link_to("Delete", "/admin/backuprestores/#\{r.id}", "data-method": :delete,
            "data-confirm": "Are you sure you want to delete this?",
            class: "member_link")
      end

  ### Associations

  By default, ExAdmin will attempt to render a belongs_to association with a 
  select control, using name field in the association. If you would like to 
  render an association with another field name, or would like to use more than 
  one field, use the :field option. 

      column :account, fields: [:username]

  ### Change the column label

  Use the :label option to override the column name:

      column :name, label: "Custom Name"


  ## As Grid

  By providing option `as: :grid` to the `index` macro, a grid index page 
  is rendered. 

  ### For Example: 

      index as: :grid, default: true do
        cell fn(p) -> 
          div do
            a href: get_route_path(conn, :show, p.id) do
              img(src: ExAdminDemo.Image.url({p.image_file_name, p}, :thumb), height: 100)
            end
          end
          a truncate(p.title), href: get_route_path(conn, :show, p.id)
        end
      end

  """

  require Logger
  require Integer
  import ExAdmin.Utils
  import ExAdmin.DslUtils
  import ExAdmin.Helpers
  import Kernel, except: [div: 2, to_string: 1]
  use Xain

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  The index macro is used to customize the index page of a resource. 
  """
  defmacro index(opts \\ [], do: block) do

    contents = quote do
      unquote(block)
    end

    quote location: :keep, bind_quoted: [options: escape(opts), contents: escape(contents)] do
      def index_view(var!(conn), page, scope_counts) do
        import ExAdmin.Register, except: [actions: 1]
        import ExAdmin.Form, except: [actions: 1]
        import ExAdmin.ViewHelpers

        var!(columns, ExAdmin.Show) = []
        var!(selectable_column, ExAdmin.Index) = nil
        var!(actions, ExAdmin.Index) = nil
        var!(cell, ExAdmin.Index) = nil
        opts = unquote(options)
        unquote(contents)

        selectable = case var!(selectable_column, ExAdmin.Index) do
          nil -> false
          other -> other
        end

        opts = Enum.into(opts, %{})
        |> Map.put(:column_list, var!(columns, ExAdmin.Show) |> Enum.reverse)
        |> Map.put(:selectable_column, selectable)

        markup do
          ExAdmin.Index.render_index_pages(var!(conn), page, scope_counts, var!(cell, ExAdmin.Index), opts)
        end
      end
    end
  end
  
  @doc """
  Define which actions will be displayed in the index view.

  ## Examples

      actions 
      actions [:new, :destroy]
  """
  defmacro actions(opts \\ quote(do: [])) do
    quote do
      var!(actions, ExAdmin.Index) = unquote(opts)
    end
  end

  @doc """
  Define a grid cell for grid view.

  ## Example
   
      index as: :grid, default: true, columns: 6 do
        import Kernel, except: [div: 2]
        cell fn(p) -> 
          div ".box" do
            div ".box-body" do
              a href: get_route_path(conn, :show, p.id) do
                img(src: ExAdminDemo.Image.url({p.image_file_name, p}, :thumb), height: 100)
              end
            end
            div ".box-footer" do
              a truncate(p.title), href: get_route_path(conn, :show, p.id)
            end
          end
        end
      end
  """
  defmacro cell(fun) do
    quote do 
      var!(cell, ExAdmin.Index) = unquote(fun)
    end
  end

  @doc """
  Add a column of selection check boxes

  Allows users to select individual rows on the index page. Selecting
  columns activates the batch actions button.
  """
  defmacro selectable_column do
    quote do
      var!(selectable_column, ExAdmin.Index) = true
    end
  end

  @doc false
  def default_index_view(conn, page, scope_counts) do
    [_, resource] = conn.path_info 

    case ExAdmin.get_registered_by_controller_route(resource) do
      nil -> 
        throw :invalid_route
      %{__struct__: _} = defn -> 
        columns = case defn.index_filters do
          [] -> []
          [false] -> []
          [f] -> f
        end
        |> case do
          [] -> 
            columns = defn.resource_model.__schema__(:fields)
            |> Enum.filter(&(not &1 in [:inserted_at, :updated_at]))
          other ->
            other
        end
        |> Enum.map(&({translate_field(defn, &1), %{}}))

        if :id in defn.resource_model.__schema__(:fields) and Enum.any?(columns, (&(elem(&1, 0) == :id))) do
          columns = Keyword.put columns, :id, %{link: true}
        end

        opts = %{}
        |> Map.put(:column_list, columns)
        |> Map.put(:selectable_column, true)

        markup do
          ExAdmin.Index.render_index_pages(var!(conn), page, scope_counts, nil, opts)
        end
    end
  end

  defp get_resource_fields([]), do: []
  defp get_resource_fields([resource | _]), do: resource.__struct__.__schema__(:fields)

  @doc false
  def render_index_pages(conn, page, scope_counts, cell, page_opts) do
    name = resource_model(conn) |> titleize |> Inflex.pluralize
    defn = ExAdmin.get_registered_by_controller_route(conn.params["resource"])
    label = get_resource_label(conn) |> Inflex.pluralize
    count = page.total_entries

    opts = %{
      columns: Map.get(page_opts, :columns, 3),
      column_list: Map.get(page_opts, :column_list),
      count: page.total_entries, 
      name: name, 
      order: ExQueb.get_sort_order(conn.params["order"]), 
      href: get_route_path(conn, :index) <> "?order=",
      defn: defn,
      batch_actions: not false in defn.batch_actions,
      scopes: defn.scopes, 
      label: label, 
      resource_model: conn.params["resource"], 
      page: page, 
      cell: cell,
      scope_counts: scope_counts,
      opts: page_opts,
      resources: page.entries, 
      selectable_column: page_opts[:selectable_column]
    }
    _render_index_page(conn, opts, page_opts)
  end

  defp _render_index_page(conn, opts, %{as: :grid}) do
    Module.concat(conn.assigns.theme, Index).wrap_index_grid fn -> 
      Module.concat(conn.assigns.theme, Index).batch_action_form conn, 
          false, opts[:scopes], opts[:resource_model], opts[:scope_counts], fn -> 
        if opts[:count] == 0 do
          Module.concat(conn.assigns.theme, Index).blank_slate_page(conn, opts)
        else
          Module.concat(conn.assigns.theme, Index).paginated_collection_grid(conn, opts)
        end
      end
    end
  end
  defp _render_index_page(conn, opts, page_opts) do
    page = opts[:page]
    actions = opts[:actions]
    opts = Map.put(opts, :fields, get_resource_fields page.entries)
    selectable = opts[:selectable_column] and opts[:batch_actions]
    columns = page_opts[:column_list]

    columns = unless Enum.any? columns, &((elem &1, 0) == "Actions") or is_nil(actions) do
      columns ++ [{"Actions", %{fun: fn(resource) -> build_index_links(conn, resource, actions) end}}]
    else
      columns
    end

    Module.concat(conn.assigns.theme, Index).wrap_index_grid fn -> 
      Module.concat(conn.assigns.theme, Index).batch_action_form conn, 
          opts[:batch_actions], opts[:scopes], opts[:resource_model], opts[:scope_counts], fn -> 
        if opts[:count] == 0 do
          Module.concat(conn.assigns.theme, Index).blank_slate_page(conn, opts)
        else
          Module.concat(conn.assigns.theme, Index).paginated_collection_table(conn, opts)
        end
      end
    end
  end

  @doc """
  Build the scope link.
  """
  def build_scope_href(href, nil), do: href
  def build_scope_href(href, scope) do
    String.replace(href, "?", "?scope=#{scope}&")
  end

  @doc """
  Build the order link.
  """
  def build_order_href(href, {name, sort}), do: href <> "#{name}_#{sort}"
  def build_order_href(href, _), do: href

  @doc """
  Build the filter link.
  """
  def build_filter_href(href, nil), do: href
  def build_filter_href(href, q) do 
    q
    |> Map.to_list
    |> Enum.reduce(href, fn({name, value}, acc) -> 
      acc <> "&q%5B" <> name <> "%5D=" <> value
    end)
  end

  @doc false
  def download_links(conn) do
    div ".download_links Download: " do
      a "CSV", href: "#{get_route_path(conn, :index)}/csv"
    end
  end

  @doc false
  def parameterize(name, seperator \\ "_")
  def parameterize(atom, seperator) when is_atom(atom) do
    Atom.to_string(atom)
    |> parameterize(seperator)
  end
  def parameterize(string, seperator) do
    Inflex.parameterize(string, seperator)
  end

  @doc false
  def build_index_links(conn, resource, actions) do
    resource_model = resource.__struct__

    links = case actions do
      [] -> [:show, :edit, :destroy]
      nil -> []
      other -> other
    end

    list = get_authorized_links(conn, resource_model)
    |> Enum.filter(&(&1 in links))
    |> Enum.reverse

    Module.concat(conn.assigns.theme, Index).handle_action_links(list, conn, resource)
  end

  @doc false
  def get_authorized_links(conn, resource_model) do
    Enum.reduce [:show, :edit, :destroy], [], fn(item, acc) -> 
      if ExAdmin.Utils.authorized_action?(conn, item, resource_model),
        do: [item | acc], else: acc
    end
  end
end
