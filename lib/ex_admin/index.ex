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
            selectable_column()

            column :id
            column :name
            actions       # display the default actions column
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
          markup do
            div do
              a href: admin_resource_path(p, :show) do
                img(src: ExAdminDemo.Image.url({p.image_file_name, p}, :thumb), height: 100)
              end
            end
            a truncate(p.title), href: admin_resource_path(p, :show)
          end
        end
      end

  """

  require Logger
  require Integer
  import ExAdmin.Utils
  import ExAdmin.Helpers
  import ExAdmin.Gettext
  import Kernel, except: [div: 2, to_string: 1]
  use Xain
  # alias ExAdmin.Schema

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @default_actions [:show, :edit, :delete]

  @doc """
  The index macro is used to customize the index page of a resource.
  """
  defmacro index(opts \\ [], do: contents) do
    quote location: :keep do
      import ExAdmin.CSV, only: [csv: 1, csv: 2]
      import ExAdmin.Register
      import ExAdmin.Index

      def index_view(var!(conn), page, scope_counts) do
        import ExAdmin.Form, except: [actions: 1]
        import ExAdmin.Register, except: [actions: 1]
        import ExAdmin.ViewHelpers

        var!(columns, ExAdmin.Show) = []
        var!(selectable_column, ExAdmin.Index) = nil
        var!(actions, ExAdmin.Index) = nil
        var!(cell, ExAdmin.Index) = nil
        opts = unquote(opts)
        unquote(contents)

        selectable =
          case Macro.expand(var!(selectable_column, ExAdmin.Index), __ENV__) do
            nil -> false
            other -> other
          end

        actions =
          ExAdmin.Index.get_index_actions(var!(conn).assigns.defn, var!(actions, ExAdmin.Index))

        opts =
          Enum.into(opts, %{})
          |> Map.put(:column_list, var!(columns, ExAdmin.Show) |> Enum.reverse())
          |> Map.put(:selectable_column, selectable)
          |> Map.put(:actions, actions)

        markup safe: true do
          ExAdmin.Index.render_index_pages(
            var!(conn),
            page,
            scope_counts,
            var!(cell, ExAdmin.Index),
            opts
          )
        end
      end
    end
  end

  @doc false
  def get_index_actions(defn, actions) do
    actions =
      case actions do
        [] -> @default_actions
        nil -> @default_actions
        false -> []
        list -> list
      end

    actions -- @default_actions -- defn.actions
  end

  @doc """
  Define which actions will be displayed in the index view.

  ## Examples

      actions
      actions [:new, :delete]
  """
  defmacro actions(opts \\ []) do
    if opts != nil and opts != false and opts -- @default_actions != [] do
      raise ArgumentError, "Only #{inspect(@default_actions)} are allowed!"
    end

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
              a href: admin_resource_path(p, :show) do
                img(src: ExAdminDemo.Image.url({p.image_file_name, p}, :thumb), height: 100)
              end
            end
            div ".box-footer" do
              a truncate(p.title), href: admin_resource_path(p, :show)
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
    case conn.assigns.defn do
      nil ->
        throw(:invalid_route)

      %{__struct__: _} = defn ->
        columns =
          case defn.index_filters do
            [] ->
              []

            [false] ->
              []

            [_] ->
              ExAdmin.Filter.fields(conn.assigns.defn)
              |> Keyword.keys()
          end
          |> case do
            [] ->
              defn.resource_model.__schema__(:fields)
              |> Enum.filter(&(&1 not in [:inserted_at, :updated_at]))

            other ->
              other
          end
          |> Enum.map(&{translate_field(defn, &1), %{}})

        columns =
          if :id in defn.resource_model.__schema__(:fields) and
               Enum.any?(columns, &(elem(&1, 0) == :id)) do
            Keyword.put(columns, :id, %{link: true})
          else
            columns
          end

        opts =
          %{}
          |> Map.put(:column_list, columns)
          |> Map.put(:selectable_column, true)
          |> Map.put(:actions, get_index_actions(defn, []))

        markup safe: true do
          ExAdmin.Index.render_index_pages(var!(conn), page, scope_counts, nil, opts)
        end
    end
  end

  defp get_resource_fields([]), do: []
  defp get_resource_fields([resource | _]), do: resource.__struct__.__schema__(:fields)

  @doc false
  def render_index_pages(conn, page, scope_counts, cell, page_opts) do
    # require IEx
    # IEx.pry
    name = resource_model(conn) |> titleize |> Inflex.pluralize()
    defn = conn.assigns.defn
    label = get_resource_label(conn) |> Inflex.pluralize()
    batch_actions = false not in defn.batch_actions and :delete in page_opts[:actions]

    opts = %{
      columns: Map.get(page_opts, :columns, 3),
      column_list: Map.get(page_opts, :column_list),
      count: page.total_entries,
      name: name,
      order: ExQueb.get_sort_order(conn.params["order"]),
      href: admin_resource_path(conn, :index) <> "?order=",
      defn: defn,
      batch_actions: batch_actions,
      scopes: defn.scopes,
      label: label,
      resource_model: conn.params["resource"],
      page: page,
      cell: cell,
      scope_counts: scope_counts,
      opts: page_opts,
      resources: page.entries,
      selectable_column: page_opts[:selectable_column],
      actions: page_opts[:actions]
    }

    _render_index_page(conn, opts, page_opts)
  end

  defp _render_index_page(conn, opts, %{as: :grid}) do
    Module.concat(conn.assigns.theme, Index).wrap_index_grid(fn ->
      Module.concat(conn.assigns.theme, Index).batch_action_form(
        conn,
        false,
        opts[:scopes],
        opts[:resource_model],
        opts[:scope_counts],
        fn ->
          if opts[:count] == 0 do
            Module.concat(conn.assigns.theme, Index).blank_slate_page(conn, opts)
          else
            Module.concat(conn.assigns.theme, Index).paginated_collection_grid(conn, opts)
          end
        end
      )
    end)
  end

  defp _render_index_page(conn, opts, page_opts) do
    page = opts[:page]
    actions = opts[:actions]
    opts = Map.put(opts, :fields, get_resource_fields(page.entries))
    columns = page_opts[:column_list]
    custom_actions_column? = Enum.any?(columns, &(elem(&1, 0) == "Actions"))

    columns =
      if custom_actions_column? || Enum.empty?(actions) do
        columns
      else
        columns ++
          [
            {"Actions",
             %{
               fun: fn resource ->
                 build_index_links(conn, resource, actions, page.page_number)
               end,
               label: ExAdmin.Gettext.gettext("Actions")
             }}
          ]
      end

    opts = Map.put(opts, :column_list, columns)

    Module.concat(conn.assigns.theme, Index).wrap_index_grid(fn ->
      Module.concat(conn.assigns.theme, Index).batch_action_form(
        conn,
        opts[:batch_actions],
        opts[:scopes],
        opts[:resource_model],
        opts[:scope_counts],
        fn ->
          if opts[:count] == 0 do
            Module.concat(conn.assigns.theme, Index).blank_slate_page(conn, opts)
          else
            Module.concat(conn.assigns.theme, Index).paginated_collection_table(conn, opts)
          end
        end
      )
    end)
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
    |> Map.to_list()
    |> Enum.reduce(href, fn {name, value}, acc ->
      acc <> "&q%5B" <> name <> "%5D=" <> value
    end)
  end

  @doc false
  def download_links(conn, opts) do
    markup do
      div ".download_links " <> gettext("Download:") <> " " do
        a("CSV", href: build_csv_href(conn, opts))
      end
    end
  end

  @doc false
  def build_csv_href(conn, opts) do
    (admin_resource_path(conn, :csv) <> "?order=")
    |> build_scope_href(conn.params["scope"])
    |> build_order_href(opts[:order])
    |> build_filter_href(conn.params["q"])
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
  def build_index_links(conn, resource, actions, page_num \\ 1) do
    resource_model = resource.__struct__

    links =
      case actions do
        nil -> []
        other -> other
      end

    list = get_authorized_links(conn, links, resource_model) |> Enum.reverse()
    labels = conn.assigns.defn.action_labels

    Module.concat(conn.assigns.theme, Index).handle_action_links(list, resource, labels, page_num)
  end

  @doc false
  def get_authorized_links(conn, links, resource_model) do
    Enum.reduce(links, [], fn item, acc ->
      if ExAdmin.Utils.authorized_action?(conn, item, resource_model), do: [item | acc], else: acc
    end)
  end
end
