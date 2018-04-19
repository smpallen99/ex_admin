defmodule ExAdmin.Show do
  @moduledoc """
  Override the default show page for an ExAdmin resource.

  By default, ExAdmin renders the show page without any additional
  configuration. It renders each column in the model, except the id,
  inserted_at, and updated_at columns in an attributes table.

  To customize the show page, use the `show` macro.

  ## Examples

      register_resource Survey.Seating do
        show seating do
          attributes_table do
            row :id
            row :name
            row :image, [image: true, height: 100], &(ExAdminDemo.Image.url({&1.image, &1}, :thumb))
          end
          panel "Answers" do
            table_for(seating.answers) do
              column "Question", fn(answer) ->
                "#\{answer.question.name}"
              end
              column "Answer", fn(answer) ->
                "#\{answer.choice.name}"
              end
            end
          end
        end

  """
  import ExAdmin.Helpers
  import ExAdmin.Repo, only: [repo: 0]

  import Kernel, except: [div: 2]
  use Xain

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Customize the show page.

  Refer to the other examples in this Module.

  ## Example

      register_resource MyProject.User do
        show user do
          attributes_table
        end
      end

  """
  defmacro show(resource, do: contents) do
    quote location: :keep do
      import ExAdmin.CSV, only: [csv: 1, csv: 2]
      import ExAdmin.Register

      def show_view(var!(conn), unquote(resource) = var!(resource)) do
        import ExAdmin.Utils
        import ExAdmin.ViewHelpers
        _ = var!(resource)

        markup safe: true do
          unquote(contents)
        end
      end
    end
  end

  @doc """
  Display a table of the model's attributes.

  When called with a block, the rows specified in the block will be
  displayed.

  When called without a block, the default attributes table will be
  displayed.

  Call with opts:

  * `only: list` - select which fields to show.
  * `except: field_list` - select which fields to exclude.
  * `all: true` - include fields :id, :inserted_at, :updated_at which are excluded by default.

  ## Examples

      # only fields :name and :email
      attributes_table do
        row :name
        row :email
      end

      # all fields including :id, :inserted_at, :updated_at
      attributes_table all: true

      # only fields :name and :email
      attributes_table only: [:name, :email]

      # all fields except :password, :id, :inserted_at, :updated_at
      attributes_table except: [:password]

      # all fields except :password
      attributes_table except: [:password], all: true

  """
  defmacro attributes_table(name \\ nil, opts_or_block)

  defmacro attributes_table(name, do: block) do
    quote location: :keep do
      var!(rows, ExAdmin.Show) = []
      unquote(block)
      rows = var!(rows, ExAdmin.Show) |> Enum.reverse()
      schema = %{name: unquote(name), rows: rows}
      ExAdmin.Table.attributes_table(var!(conn), var!(resource), schema)
    end
  end

  defmacro attributes_table(_, opts) do
    quote location: :keep do
      ExAdmin.Show.default_attributes_table(var!(conn), var!(resource), unquote(opts))
    end
  end

  @doc """
  Display a table of the model's default attributes.

  ## Examples

      # all fields except :id, :inserted_at, :updated_at
      attributes_table

  """
  defmacro attributes_table do
    quote location: :keep do
      ExAdmin.Show.default_attributes_table(var!(conn), var!(resource))
    end
  end

  @doc """
  Display a table of a specific model's attributes.

  When called with a block, the rows specified in the block will be
  displayed.

  When called without a block, the default attributes table will be
  displayed.
  """
  defmacro attributes_table_for(resource, do: block) do
    quote location: :keep do
      var!(rows, ExAdmin.Show) = []
      unquote(block)
      rows = var!(rows, ExAdmin.Show) |> Enum.reverse()
      resource = unquote(resource)
      schema = %{rows: rows}
      ExAdmin.Table.attributes_table_for(var!(conn), resource, schema)
    end
  end

  @doc """
  Adds a new panel to the show page.

  The block given must include one of two commands:

  * `table_for` - Displays a table for a `:has_many` association.

  * `contents` - Add HTML to a panel
  """
  defmacro panel(name \\ "", opts \\ [], do: block) do
    quote do
      var!(elements, ExAdmin.Show) = []
      unquote(block)

      ExAdmin.Table.panel(
        var!(conn),
        [{:name, unquote(name)}, {:opts, unquote(opts)} | var!(elements, ExAdmin.Show)],
        unquote(opts)
      )
    end
  end

  @doc """
  Add a table for a `:has_many` association or a list of maps.

  ## Examples

  ### has_many association

      show account do
        attributes_table do
          row :username
          row :email
          row :contact
        end
        panel "Inventory" do
          table_for account.inventory do
            column "Asset", &__MODULE__.inventory_name/1
            column "PO", &(&1.sales_order.po)
            column :quantity
          end
        end
      end

  ### Array of maps

      show user do
        attributes_table do
          row :name
        end
        panel "Addresses" do
          table_for user.addresses do
            column :street
            column :city
          end
        end
      end

  """
  defmacro table_for(resources, opts, do: block) do
    block =
      if Keyword.has_key?(opts, :sortable) do
        ensure_sort_handle_column(block)
      else
        block
      end

    quote do
      opts = unquote(opts) |> ExAdmin.Show.prepare_sortable_opts()

      var!(columns, ExAdmin.Show) = []
      unquote(block)
      columns = var!(columns, ExAdmin.Show) |> Enum.reverse()

      var!(elements, ExAdmin.Show) =
        var!(elements, ExAdmin.Show) ++
          [
            {
              :table_for,
              %{resources: unquote(resources), columns: columns, opts: opts}
            }
          ]
    end
  end

  defmacro table_for(resources, do: block) do
    quote do
      table_for(unquote(resources), [], do: unquote(block))
    end
  end

  defp ensure_sort_handle_column({:__block__, trace, cols} = block) do
    has_sort_handle_column = Enum.any?(cols, fn {ctype, _, _} -> ctype == :sort_handle_column end)

    if has_sort_handle_column do
      block
    else
      {:__block__, trace, [{:sort_handle_column, [], nil} | cols]}
    end
  end

  def prepare_sortable_opts(opts) do
    case opts[:sortable] do
      [resource: resource, assoc_name: assoc_name] ->
        path = ExAdmin.Utils.admin_association_path(resource, assoc_name, :update_positions)

        [
          class: "table sortable",
          "data-sortable-link": path
        ]
        |> Keyword.merge(Keyword.drop(opts, [:sortable]))

      _ ->
        opts
    end
  end

  defmacro sortable_table_for(resource, assoc_name, do: block) do
    quote do
      resource = unquote(resource)
      assoc_name = unquote(assoc_name)
      resources = Map.get(resource, assoc_name)

      table_for(
        resources,
        [sortable: [resource: resource, assoc_name: assoc_name]],
        do: unquote(block)
      )
    end
  end

  @doc """
  Add a markup block to a form.

  Allows the use of the Xain markup to be used in a panel.

  ## Examples

      show user do
        attributes_table

        panel "Testing" do
          markup_contents do
            div ".my-class" do
              test "Tesing"
            end
          end
        end
  """
  defmacro markup_contents(do: block) do
    quote do
      content =
        markup :nested do
          unquote(block)
        end

      var!(elements, ExAdmin.Show) =
        var!(elements, ExAdmin.Show) ++
          [
            {
              :contents,
              %{contents: content}
            }
          ]
    end
  end

  @doc """
  Add a select box to add N:M associations to the resource on show page.

  *Note:* If you have custom keys in intersection table, please use association_filler/2 to specify them explicit.

  ## Examples

      show post do
        attributes_table

        panel "Tags" do
          table_for(post.post_tags) do
            column :tag
          end
          markup_contents do
            association_filler post, :tags, autocomplete: true
          end
        end
      end
  """
  defmacro association_filler(resource, assoc_name, opts) do
    quote bind_quoted: [resource: resource, assoc_name: assoc_name, opts: opts] do
      opts =
        ExAdmin.Schema.get_intersection_keys(resource, assoc_name)
        |> Keyword.merge(assoc_name: to_string(assoc_name))
        |> Keyword.merge(opts)

      association_filler(resource, opts)
    end
  end

  @doc """
  Add a select box to add N:M associations to the resource on show page.

  ## Options

  * `resource_key` - foreign key in the intersection table for resource model
  * `assoc_name` - name of association
  * `assoc_key` - foreign key in the intersection table for association model
  * `assoc_model` - association Ecto model
  * `autocomplete` - preload all possible associations if `false` and use autocomplete if `true`

  ## Examples

      show post do
        attributes_table

        panel "Tags" do
          table_for(post.post_tags) do
            column :tag
          end
          markup_contents do
            association_filler(post, resource_key: "post_id", assoc_name: "tags",
              assoc_key: "tag_id", autocomplete: false)
          end
        end
      end
  """
  defmacro association_filler(resource, opts) do
    quote bind_quoted: [resource: resource, opts: opts] do
      required_opts = [:resource_key, :assoc_name, :assoc_key]

      unless MapSet.subset?(MapSet.new(required_opts), MapSet.new(Keyword.keys(opts))) do
        raise ArgumentError.exception("""
                `association_filler` macro requires following options:
                #{inspect(required_opts)}
                For example:
                association_filler(category, resource_key: "category_id", assoc_name: "properties",
                  assoc_key: "property_id", autocomplete: false)
              """)
      end

      hr
      h4(opts[:label] || "Enter new #{opts[:assoc_name]}")
      ExAdmin.Show.build_association_filler_form(resource, opts[:autocomplete], opts)
    end
  end

  @doc false
  def build_association_filler_form(resource, true = _autocomplete, opts) do
    path = ExAdmin.Utils.admin_association_path(resource, opts[:assoc_name], :add)

    markup do
      Xain.form class: "association_filler_form",
                name: "select_#{opts[:assoc_name]}",
                method: "post",
                action: path do
        Xain.input(
          name: "_csrf_token",
          value: Plug.CSRFProtection.get_csrf_token(),
          type: "hidden"
        )

        Xain.input(name: "resource_key", value: opts[:resource_key], type: "hidden")
        Xain.input(name: "assoc_key", value: opts[:assoc_key], type: "hidden")

        Xain.select class: "association_filler", multiple: "multiple", name: "selected_ids[]" do
          option("")
        end

        Xain.input(
          value: "Save",
          type: "submit",
          class: "btn btn-primary",
          style: "margin-left: 1em;"
        )
      end

      associations_path = ExAdmin.Utils.admin_association_path(resource, opts[:assoc_name])

      script type: "text/javascript" do
        text("""
        $(document).ready(function() {
          ExAdmin.association_filler_opts.ajax.url = "#{associations_path}";
          $(".association_filler").select2(ExAdmin.association_filler_opts);
        });
        """)
      end
    end
  end

  @doc false
  def build_association_filler_form(resource, _autocomplete, opts) do
    assoc_name = String.to_existing_atom(opts[:assoc_name])
    assoc_defn = ExAdmin.get_registered_by_association(resource, assoc_name)
    path = ExAdmin.Utils.admin_association_path(resource, opts[:assoc_name], :add)

    Xain.form class: "association_filler_form",
              name: "select_#{opts[:assoc_name]}",
              method: "post",
              action: path do
      Xain.input(name: "_csrf_token", value: Plug.CSRFProtection.get_csrf_token(), type: "hidden")
      Xain.input(name: "resource_key", value: opts[:resource_key], type: "hidden")
      Xain.input(name: "assoc_key", value: opts[:assoc_key], type: "hidden")

      Xain.select class: "select2", multiple: "multiple", name: "selected_ids[]" do
        ExAdmin.Model.potential_associations_query(resource, assoc_defn.__struct__, assoc_name)
        |> repo().all
        |> Enum.each(fn opt ->
          option(ExAdmin.Helpers.display_name(opt), value: ExAdmin.Schema.get_id(opt))
        end)
      end

      Xain.input(
        value: "Save",
        type: "submit",
        class: "btn btn-primary",
        style: "margin-left: 1em;"
      )
    end
  end

  @doc false
  def default_show_view(conn, resource) do
    markup safe: true do
      default_attributes_table(conn, resource)
    end
  end

  @doc false
  def default_attributes_table(conn, resource, opts \\ []) do
    case conn.assigns.defn do
      nil ->
        throw(:invalid_route)

      %{__struct__: _} = defn ->
        columns =
          defn.resource_model.__schema__(:fields)
          |> get_default_attributes(Enum.into(opts, %{}))
          |> Enum.map(&{translate_field(defn, &1), %{}})
          |> Enum.reject(&is_nil(&1))

        ExAdmin.Table.attributes_table(conn, resource, %{rows: columns})
    end
  end

  defp get_default_attributes(fields, %{only: only}) do
    Enum.filter(only, &(&1 in fields))
  end

  defp get_default_attributes(fields, %{except: except} = opts) do
    get_default_attributes(fields, Map.delete(opts, :except)) -- except
  end

  defp get_default_attributes(fields, %{all: true}), do: fields

  defp get_default_attributes(fields, _) do
    fields
    |> Enum.reject(&(&1 in [:id, :inserted_at, :updated_at]))
  end
end
