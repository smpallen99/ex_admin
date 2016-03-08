defmodule ExAdmin.Register do
  @moduledoc """
  Allows registering a resource or a page to be displayed with ExAdmin.

  For each model you wanted rendered by ExAdmin, use the 
  `register_resource` call. For each general page (like a dashboard), 
  use the `register_page` call.

  To allow ExAdmin to manage the resource with defaults, do not place 
  any additional code in the block of `register_resource`.

  ## Examples

  Register the Survey.Answer model with all defaults.

      defmodule Survey.ExAdmin.Answer do
        use ExAdmin.Register

        register_resource Survey.Answer do
        end
      end

  ## Commands available in the register_resource do block 
  
  * `menu` - Customize the properties of the menu item
  * `index` - Customize the index page 
  * `show` - Customize the show page
  * `form` - Customize the form page 
  * `query` - Customize the `Ecto` queries for each page
  * `options` - Change various options for a resource
  * `member_action` - Add a custom action for id based requests
  * `filter` - Disable/Customize the filter pages  
  * `controller` - Override the default controller
  * `actions` - Define which actions are available for a resource
  * `batch_actions` - Customize the batch_actions shown on the index page
  * `csv` - Customize the csv export file
  * `collection_action` - Add a custom action for collection based requests
  * `clear_action_items!` - Remove the action item buttons
  * `action_item` - Defines custom action items

  """

  @filename "/tmp/ex_admin_registered" 

  import ExAdmin.Utils

  defmacro __using__(_) do
    quote do
      use ExAdmin.Index
      use ExAdmin.Show
      use ExAdmin.Form, except: [actions: 1]
      use ExAdmin.CSV
      import unquote(__MODULE__)
      import Ecto.Query, only: [from: 2]
      import Xain, except: [input: 1, input: 2, input: 3, menu: 1, form: 2]
      Module.register_attribute __MODULE__, :member_actions, accumulate: true, persist: true
      Module.register_attribute __MODULE__, :collection_actions, accumulate: true, persist: true
    end
  end

  File.rm @filename
  File.touch @filename

  @doc """
  Register an Ecto model.

  Once registered, ExAdmin adds the resource to the administration
  pages. If no additional code is added to the do block, the resource 
  will be rendered with defaults, including:

  * A paginated index page listing all columns in the model's database
    table
  * A details page (show) listing fields and simple associations
  * Need and and edit pages
  * A menu item
  * A CSV export link on the index page

  """
  defmacro register_resource(mod, [do: block]) do
    quote location: :keep do
      require Logger
      Module.register_attribute __MODULE__, :query, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :index_filters, accumulate: true, persist: true 
      Module.register_attribute __MODULE__, :batch_actions, accumulate: true, persist: true 
      Module.register_attribute __MODULE__, :selectable_column, accumulate: false, persist: true
      Module.register_attribute(__MODULE__, :form_items, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :controller_plugs, accumulate: true, persist: true)
      module = unquote(mod) 
      Module.put_attribute(__MODULE__, :module, module)
      Module.put_attribute(__MODULE__, :query, nil)
      Module.put_attribute(__MODULE__, :selectable_column, nil)

      alias unquote(mod)
      import Ecto.Query
      
      def config do
        apply __MODULE__, :__struct__, []
      end
      
      unquote(block)

      query_opts = case Module.get_attribute(__MODULE__, :query) do
        nil -> 
          list = module.__schema__(:associations)
          |> Enum.map(&(ExAdmin.Register.build_query_association module, &1))
          |> Enum.filter(&(not is_nil(&1)))
          query = %{all: [preload: list]}
          Module.put_attribute __MODULE__, :query, query
          query
        other -> other
      end

      controller = case Module.get_attribute(__MODULE__, :controller) do
        nil -> 
          controller_mod = String.to_atom("#{module}Controller")
          Module.put_attribute(__MODULE__, :controller, controller_mod)
        other -> 
          Logger.warn "Should not get here - controller: #{inspect other}"
      end

      menu_opts = case Module.get_attribute(__MODULE__, :menu) do
        nil -> 
          %{ priority: 10, 
             label: (base_name(module) |> Inflex.pluralize)}
        other -> 
          Enum.into other, %{}
      end
      all_options = [:edit, :show, :new, :delete]
      actions = case Module.get_attribute(__MODULE__, :actions) do
        nil -> all_options
        list when is_list(list) -> list
        opts -> 
          case Enum.into opts, %{} do
            %{except: except} -> all_options -- except
            %{only: only} -> only
          end
      end

      controller_route = (base_name(module) |> Inflex.underscore |> Inflex.pluralize)
      case Module.get_attribute(__MODULE__, :options) do 
        nil -> nil
        options -> 
          controller_route = Keyword.get(options, :controller_route, controller_route)
      end
      plugs = case Module.get_attribute(__MODULE__, :controller_plugs) do
        nil -> []
        list -> Enum.reverse list
      end

      defstruct controller: @controller, 
                controller_methods: Module.get_attribute(__MODULE__, :controller_methods),
                title_actions: &ExAdmin.default_resource_title_actions/2,
                type: :resource,
                resource_model: module,
                query_opts: query_opts,
                controller_route: controller_route,
                menu: menu_opts, 
                actions: actions, 
                member_actions: Module.get_attribute(__MODULE__, :member_actions),
                collection_actions: Module.get_attribute(__MODULE__, :collection_actions),
                controller_filters: Module.get_attribute(__MODULE__, :controller_filters), 
                index_filters: Module.get_attribute(__MODULE__, :index_filters),
                selectable_column: Module.get_attribute(__MODULE__, :selectable_column), 
                batch_actions: Module.get_attribute(__MODULE__, :batch_actions), 
                plugs: plugs 


      def run_query(repo, action, id \\ nil) do
        %__MODULE__{}
        |> Map.get(:resource_model)
        |> ExAdmin.Query.run_query(repo, action, id, @query)
      end

      def plugs(), do: @controller_plugs

      File.write!(unquote(@filename), "#{__MODULE__}\n", [:append])
    end
  end

  @doc """
  Override the controller for a resource.

  Allows custom actions, filters, and plugs for the controller. Commands 
  in the controller block include:

  * `define_method` - Create a controller action with the body of
    the action
  * `before_filter` - Add a before_filter to the controller
  * `redirect_to` - Redirects to another page
  * `plug` - Add a plug to the controller

  """
  defmacro controller([do: block]) do
    quote do
      Module.register_attribute(__MODULE__, :controller_methods, accumulate: false, persist: true)
      Module.register_attribute(__MODULE__, :controller_filters, accumulate: true, persist: true)
      Module.put_attribute(__MODULE__, :controller_methods, [])

      unquote(block)
    end
  end
  defmacro controller(controller_mod) do
    quote do
      Module.put_attribute __MODULE__, :controller, unquote(controller_mod)
    end
  end

  @doc """
  Override an action on a controller.

  Allows the customization of controller actions. 

  ## Examples

  Override the index action to redirect to the root page.

      controller do
        define_method(:index) do
          redirect_to "/"
        end
      end


  """
  defmacro define_method(name, [do: block]) do
    quote do
      methods = Module.get_attribute(__MODULE__, :controller_methods)

      Module.put_attribute(__MODULE__, :controller_methods, [{unquote(name), []} | methods])
      unquote(block)
    end
  end

  @doc """
  Add a before_filter to a controller.

  The before filter is executed before the controller action(s) are
  executed.

  Normally, the function should return the conn struct. However, if you 
  want to modify the params, then return the tuple `{conn, new_parms}`.

  ## Examples

  The following example illustrates how to add a sync action that will
  be run before the index page is loaded.

      controller do 
        before_filter :sync, only: [:index]

        def sync(conn, _) do
          BackupRestore.sync
          conn
        end
      end

      controller do 
        before_filter :no_change, except: [:create, :modify]

        def no_change(conn, params) do
          {conn, put_in(params, [:setting, :no_mod], true)}
        end
      end
  """
  defmacro before_filter(name, opts) do
    quote location: :keep do
      Module.put_attribute(__MODULE__, :controller_filters, {:before_filter, {unquote(name), unquote(opts)}})
    end
  end

  @doc """
  Redirect to a given path.

  Use this command in a controller block to redirect to another page.
  """
  defmacro redirect_to(path) do
    quote do
      [{name, opts} | tail] = Module.get_attribute(__MODULE__, :controller_methods)
      new_opts = [{:redirect_to, unquote(path)} | opts]
      Module.put_attribute(__MODULE__, :controller_methods, [{name, new_opts} | tail])
    end
  end

  @doc """
  Add a plug to the controller.

  Add custom plugs to a controller.

  ## Example 

      controller do
        plug :my_plug, the_answer: 42
      end

  """
  defmacro plug(name, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :controller_plugs, {unquote(name), unquote(opts)})
    end
  end

  @doc """
  Register a static page.

  Use `register_page` to create a static page, like a dashboard, or
  welcome page to the admin interface.

  See the default dashboard page for an example.
  """
  defmacro register_page(name, [do: block]) do
    quote location: :keep do
      use ExAdmin.Page

      Module.register_attribute __MODULE__, :query, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :index_filters, accumulate: true, persist: true 
      Module.register_attribute __MODULE__, :batch_actions, accumulate: true, persist: true 
      Module.register_attribute __MODULE__, :selectable_column, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :form_items, accumulate: true, persist: true
      Module.put_attribute __MODULE__, :controller_plugs, nil 
      page_name = unquote(name)
      unquote(block)

      # query_opts = Module.get_attribute(__MODULE__, :query)
      menu_opts = case Module.get_attribute(__MODULE__, :menu) do
        :none -> 
          %{none: true}
        nil -> 
          %{label: page_name, priority: 99}
        other -> 
          Enum.into other, %{}
      end

      controller_methods = Module.get_attribute(__MODULE__, :controller_methods)
      page_name = Kernel.to_string(page_name)

      plugs = case Module.get_attribute(__MODULE__, :controller_plugs) do
        nil -> []
        list -> Enum.reverse list
      end

      # defstruct controller: Module.concat(Application.get_env(:ex_admin, :project), AdminController),
      #           controller_methods: controller_methods,
      #           type: :page,
      #           resource_model: resource_model,
      #           title_actions: &ExAdmin.default_page_title_actions/2,
      #           controller_route: (page_name |> Inflex.parameterize("_")),
      #           menu: menu_opts, 
      #           plugs: plugs

      defstruct controller: Module.concat(Application.get_env(:ex_admin, :project), AdminController),
                controller_methods: Module.get_attribute(__MODULE__, :controller_methods),
                type: :page,
                page_name: page_name,
                title_actions: &ExAdmin.default_page_title_actions/2,
                controller_route: (page_name |> Inflex.parameterize("_")),
                menu: menu_opts, 

                member_actions: Module.get_attribute(__MODULE__, :member_actions),
                collection_actions: Module.get_attribute(__MODULE__, :collection_actions),
                controller_filters: Module.get_attribute(__MODULE__, :controller_filters), 
                index_filters: [false],
                # selectable_column: Module.get_attribute(__MODULE__, :selectable_column), 
                batch_actions: Module.get_attribute(__MODULE__, :batch_actions), 
                plugs: plugs 

      # def run_query(repo, action, id \\ nil) do
      #   %__MODULE__{}
      #   |> Map.get(:resource_model)
      #   |> ExAdmin.Query.run_query(repo, action, id, @query)
      # end

      def plugs(), do: @controller_plugs


      File.write!(unquote(@filename), "#{__MODULE__}\n", [:append])
    end
  end

  @doc """
  Customize the resource admin page by setting options for the page.

  The available actions are: 

  * TBD
  """
  defmacro options(opts) do
    quote do
      Module.put_attribute __MODULE__, :options, unquote(opts)
    end
  end

  @doc """
  Customize the menu of a page.

  The available options are:
  
  * `:priority` - Sets the position of the menu, with 0 being the 
    left most menu item 
  * `:label` - The name used in the menu
  * `:if` - Only display the menu item if the condition returns non false/nil

  ## Examples

  The following example adds a custom label, sets the priority, and is
  only displayed if the current user is a superadmin.

      menu label: "Backup & Restore", priority: 14, if: &__MODULE__.is_superadmin/1

  This example disables the menu item:

      menu :none

  """
  defmacro menu(opts) do
    quote do
      Module.put_attribute __MODULE__, :menu, unquote(opts)
    end 
  end

  @doc """
  Add query options to the Ecto queries.

  For the most part, use `query` to setup preload options. Query 
  customization can be done for all pages, or individually specified. 

  ## Examples
  
  Load the belongs_to :category, has_many :phone_numbers, and 
  the has_many :groups for all pages for the resource.

      query do
        %{
          all: [preload: [:category, :phone_numbers, :groups]],
        }
      end

  Load the has_many :contacts association, as well as the has_many
  :phone_numbers of the contact

      query do 
        %{show: [preload: [contacts: [:phone_numbers]]] }
      end

  A more complicated example that defines a default preload, with a 
  more specific preload for the show page.

      query do 
        %{
          all: [preload: [:group]],
          show: [preload: [:group, messages: [receiver: [:category, :phone_numbers]]]]
        }
      end
  """
  defmacro query(do: qry) do
    quote do
      Module.put_attribute __MODULE__, :query, unquote(qry)
    end
  end

  @doc """
  Add a column to a table.

  Can be used on the index page, or in the table attributes on the 
  show page.

  A number of options are valid: 
  
  * `label` - Change the name of the column heading
  * `fields` - Add the fields to be included in an association
  * `link` - Set to true to add a link to an association
  * `fn/1` - An anonymous function to be called to render the field
  * `collection` - Add the collection for a belongs_to association
  """
  defmacro column(name, opts \\ [], fun \\ nil) do
    quote do
      opts = ExAdmin.DslUtils.fun_to_opts unquote(opts), unquote(fun)
      var!(columns, ExAdmin.Show) = [{unquote(name), (opts)} | var!(columns, ExAdmin.Show)]
    end
  end

  @doc """
  Add a row to the attributes table on the show page.

  See `column/3` for a list of options.
  """
  defmacro row(name, opts \\ [], fun \\ nil) do
    quote do
      opts = ExAdmin.DslUtils.fun_to_opts unquote(opts), unquote(fun)
      var!(rows, ExAdmin.Show) = [{unquote(name), opts} | var!(rows, ExAdmin.Show)]
    end
  end

  @doc """
  Add a link to a path
  """
  defmacro link_to(name, path, opts \\ quote(do: [])) do
    quote do
      opts = Keyword.merge [to: unquote(path)], unquote(opts)
      Phoenix.HTML.Link.link "#{unquote(name)}", opts
    end
  end

  @doc """
  Define which actions will be displayed.

  ## Examples

      actions :all, except: [:new, :destroy, :edit]
  """
  defmacro actions(:all, opts \\ quote(do: [])) do
    quote do
      opts = unquote(opts)
      Module.put_attribute __MODULE__, :actions, unquote(opts)
    end
  end

  @doc """
  Add an id based action.

  Member actions are those actions that act on an individual record in 
  the database.

  ## Examples

  The following example illustrates how to add a restore action to 
  a backup and restore page. 

      member_action :restore,  &__MODULE__.restore_action/2

      ...
          
      def restore_action(conn, params) do
        case BackupRestore.restore Repo.get(BackupRestore, params[:id]) do
          {:ok, filename} -> 
            Controller.put_flash(conn, :notice, "Restore \#{filename} complete.")
          {:error, message} -> 
            Controller.put_flash(conn, :error, "Restore Failed: \#{message}.")
        end
        |> Controller.redirect(to: ExAdmin.Utils.get_route_path(conn, :index))
      end

  """
  defmacro member_action(name, fun) do
    quote do
      Module.put_attribute __MODULE__, :member_actions, {unquote(name), unquote(fun)}
    end
  end

  @doc """
  Add a action that acts on the index page.

  ## Examples

  The following example shows how to add a backup action on the index
  page. 

      collection_action :backup, &__MODULE__.backup_action/2

      def backup_action(conn, _params) do
        Repo.insert %BackupRestore{}
        Controller.put_flash(conn, :notice, "Backup complete.")
        |> Controller.redirect(to: ExAdmin.Utils.get_route_path(conn, :index))
      end

  """
  defmacro collection_action(name, fun) do
    quote do
      Module.put_attribute __MODULE__, :collection_actions, {unquote(name), unquote(fun)}
    end
  end

  defmacro clear_action_items! do
    quote do
      Module.register_attribute __MODULE__, :actions, accumulate: true, persist: true
    end
  end

  @doc """
  Add a custom action button to the page.

  ## Examples

  The following example demonstrates adding a Backup Now link to the 
  index page, with no other action buttons due to the `clear_action_items!`
  call.

      clear_action_items! 

      action_item :index, fn ->
        ExAdmin.Register.link_to "Backup Now", "/admin/backuprestores/backup", "data-method": :post, id: "backup-now"
      end 
  """
  defmacro action_item(opts, fun) do
    fun = Macro.escape(fun, unquote: true)
    quote do
      Module.put_attribute __MODULE__, :actions, {unquote(opts), unquote(fun)}
    end
  end

  @doc """
  Customize the filter pages on the right side of the index page.

  ## Examples

  Disable the filter view:

      filter false

  """
  defmacro filter(false) do
    quote do
      Module.put_attribute __MODULE__, :index_filters, false
    end
  end
  defmacro filter(field, opts \\ quote(do: [])) do
    quote do 
      Module.put_attribute __MODULE__, :index_filters, {unquote(field), unquote(opts)}
    end
  end

  @doc """
  Disable the batch_actions button the index page.

  ## Examples 

      batch_actions false
  """
  defmacro batch_actions(false) do
    quote do
      Module.put_attribute __MODULE__, :batch_actions, false
    end
  end
  
  @doc false
  def build_query_association(module, field) do
    case module.__schema__(:association, field) do
      %Ecto.Association.BelongsTo{cardinality: :one} -> field
      %Ecto.Association.Has{cardinality: :many} -> 
        check_preload field, :preload_many
      _ -> 
        nil
    end
  end

  defp check_preload(field, key) do
    if Application.get_env :ex_admin, key, true do
      field
    else
      nil
    end
  end

end

