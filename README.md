# ExAdmin

[![Build Status][travis-img]][travis] [![Hex Version][hex-img]][hex] [![License][license-img]][license]

[travis-img]: https://travis-ci.org/smpallen99/ex_admin.svg?branch=master
[travis]: https://travis-ci.org/smpallen99/ex_admin
[hex-img]: https://img.shields.io/hexpm/v/ex_admin.svg
[hex]: https://hex.pm/packages/ex_admin
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

Note: This version has been updated to support both Ecto 1.1 and Ecto 2.0. See [Installation](#installation) for more information.

ExAdmin is an auto administration package for [Elixir](http://elixir-lang.org/) and the [Phoenix Framework](http://www.phoenixframework.org/), a port/inspiration of [ActiveAdmin](http://activeadmin.info/) for Ruby on Rails.

Checkout the [Live Demo](http://demo.exadmin.info/admin). The source code can be found at [ExAdmin Demo](https://github.com/smpallen99/ex_admin_demo).

Checkout this [Additional Live Demo](http://demo2.exadmin.info/admin) for examples of many-to-many relationships, nested attributes, and authentication.

See the [docs](https://hexdocs.pm/ex_admin/) and the [Wiki](https://github.com/smpallen99/ex_admin/wiki) for more information.

## Usage

ExAdmin is an add on for an application using the [Phoenix Framework](http://www.phoenixframework.org) to create a CRUD administration tool with little or no code. By running a few mix tasks to define which Ecto Models you want to administer, you will have something that works with no additional code.

Before using ExAdmin, you will need a Phoenix project and an Ecto model created.

![ExAdmin](http://exadmin.info/doc/ex_admin_blue.png)

### Installation

Add ex_admin to your deps:

#### Hex

mix.exs
```elixir
  defp deps do
     ...
     {:ex_admin, "~> 0.8"},
     ...
  end
```

#### GitHub with Ecto 2.0

mix.exs
```elixir
  defp deps do
     ...
     {:ex_admin, github: "smpallen99/ex_admin"},
     ...
  end
```

Add some admin configuration and the admin modules to the config file

config/config.exs
```elixir
config :ex_admin,
  repo: MyProject.Repo,
  module: MyProject,    # MyProject.Web for phoenix >= 1.3.0-rc 
  modules: [
    MyProject.ExAdmin.Dashboard,
  ]

```

Fetch and compile the dependency

```
mix do deps.get, deps.compile
```

Configure ExAdmin:

```
mix admin.install
```

Add the admin routes

web/router.ex
```elixir
defmodule MyProject.Router do
  use MyProject.Web, :router
  use ExAdmin.Router
  ...
  scope "/", MyProject do
    ...
  end

  # setup the ExAdmin routes on /admin
  scope "/admin", ExAdmin do
    pipe_through :browser
    admin_routes()
  end
```

Add the paging configuration

lib/my_project/repo.ex
```elixir
  defmodule MyProject.Repo do
    use Ecto.Repo, otp_app: :my_project
    use Scrivener, page_size: 10
  end

```

Edit your brunch-config.js file and follow the instructions that the installer appended to this file. This requires you copy 2 blocks and replace the existing blocks.

Start the application with `iex -S mix phoenix.server`

Visit http://localhost:4000/admin

You should see the default Dashboard page.

## Getting Started

### Adding an Ecto Model to ExAdmin

To add a model, use `admin.gen.resource` mix task:

```
mix admin.gen.resource MyModel
```

Add the new module to the config file:

config/config.exs

```elixir
config :ex_admin,
  repo: MyProject.Repo,
  module: MyProject,
  modules: [
    MyProject.ExAdmin.Dashboard,
    MyProject.ExAdmin.MyModel,
  ]
```

Start the phoenix server again and browse to `http://localhost:4000/admin/my_model`

You can now list/add/edit/and delete `MyModel`s.

### Changesets
ExAdmin will use your schema's changesets. By default we call the `changeset` function on your schema, although you
can configure the changeset we use for update and create seperately.

custom changeset:
```elixir
defmodule TestExAdmin.ExAdmin.Simple do
  use ExAdmin.Register

  register_resource TestExAdmin.Simple do
    update_changeset :changeset_update
    create_changeset :changeset_create
  end
end
```

#### Relationships

We support many-to-many and has many relationships as provided by Ecto. We recommend using cast_assoc for many-to-many relationships
and put_assoc for has-many. You can see example changesets in our [test schemas](test/support/schema.exs)

When passing in results from a form for relationships we do some coercing to make it easier to work with them in your changeset.
For collection checkboxes we will pass an array of the selected options ids to your changeset so you can get them and use put_assoc as [seen here](test/support/schema.exs#L26-L35)

In order to support has many deletions you need you to setup a virtual attribute on your schema's. On the related schema you will
need to add an _destroy virtual attribute so we can track the destroy property in the form. You will also need to cast this in your changeset. Here is an example changeset. In this scenario a User has many products and products can be deleted. We also have many roles associated.

```elixir
defmodule TestExAdmin.User do
  import Ecto.Changeset
  use Ecto.Schema
  import Ecto.Query

  schema "users" do
    field :name, :string
    field :email, :string
    field :active, :boolean, default: true
    has_many :products, TestExAdmin.Product, on_replace: :delete
    many_to_many :roles, TestExAdmin.Role, join_through: TestExAdmin.UserRole, on_replace: :delete
  end

  @fields ~w(name active email)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required([:email, :name])
    |> cast_assoc(:products, required: false)
    |> add_roles(params)
  end

  def add_roles(changeset, params) do
    if Enum.count(Map.get(params, :roles, [])) > 0 do
      ids = params[:roles]
      roles = TestExAdmin.Repo.all(from r in TestExAdmin.Role, where: r.id in ^ids)
      put_assoc(changeset, :roles, roles)
    else
      changeset
    end
  end
end

defmodule TestExAdmin.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias TestExAdmin.Repo

  schema "roles" do
    field :name, :string
    has_many :uses_roles, TestExAdmin.UserRole
    many_to_many :users, TestExAdmin.User, join_through: TestExAdmin.UserRole
  end

  @fields ~w(name)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
  end
end


defmodule TestExAdmin.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :_destroy, :boolean, virtual: true
    field :title, :string
    field :price, :decimal
    belongs_to :user, TestExAdmin.User
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, ~w(title price user_id))
    |> validate_required(~w(title price))
    |> mark_for_deletion
  end

  defp mark_for_deletion(changeset) do
    # If delete was set and it is true, let's change the action
    if get_change(changeset, :_destroy) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
```

A good blog post exisits on the Platformatec blog describing how these relationships work: http://blog.plataformatec.com.br/2015/08/working-with-ecto-associations-and-embeds/

### Customizing the index page

Use the `index do` command to define the fields to be displayed.

admin/my_model.ex
```elixir
defmodule MyProject.ExAdmin.MyModel do
  use ExAdmin.Register
  register_resource MyProject.MyModel do

    index do
      selectable_column()

      column :id
      column :name
      actions()     # display the default actions column
    end
  end
end
```

### Customizing the form

The following example shows how to customize the form with the `form` macro:

```elixir
defmodule MyProject.ExAdmin.Contact do
  use ExAdmin.Register

  register_resource MyProject.Contact do
    form contact do
      inputs do
        input contact, :first_name
        input contact, :last_name
        input contact, :email
        input contact, :register_date, type: Date # if you use Ecto :date type in your schema
        input contact, :category, collection: MyProject.Category.all
      end

      inputs "Groups" do
        inputs :groups, as: :check_boxes, collection: MyProject.Group.all
      end
    end
  end
end
```

### Customizing the show page

The following example illustrates how to modify the show page.

```elixir
defmodule MyProject.ExAdmin.Question do
  use ExAdmin.Register

  register_resource MyProject.Question do
    menu priority: 3

    show question do

      attributes_table   # display the defaults attributes

      # create a panel to list the question's choices
      panel "Choices" do
        table_for(question.choices) do
          column :key
          column :name
        end
      end
    end
  end
end
```
## Custom Types

Support for custom field types is done in two areas, rendering fields, and input controls.

### Rendering Custom Types

Use the `ExAdmin.Render.to_string/` protocol for rendering types that are not supported by ExAdmin.

For example, to support rendering a tuple, add the following file to your project:

```elixir
# lib/render.ex
defimpl ExAdmin.Render, for: Tuple do
  def to_string(tuple), do: inspect(tuple)
end
```

### Input Type

Use the `:field_type_matching` config item to set the input type.

For example, given the following project:

```elixir
defmodule ElixirLangMoscow.SpeakerSlug do
  use EctoAutoslugField.Slug, from: [:name, :company], to: :slug
end

defmodule ElixirLangMoscow.Speaker do
  use ElixirLangMoscow.Web, :model
  use Arc.Ecto.Model

  alias ElixirLangMoscow.SpeakerSlug
  schema "speakers" do
    field :slug, SpeakerSlug.Type
    field :avatar, ElixirLangMoscow.Avatar.Type
  end
end
```

Add the following to your project's configuration:

```elixir
config :ex_admin,
  # ...
  field_type_matching: %{
    ElixirLangMoscow.SpeakerSlug.Type => :string,
    ElixirLangMoscow.Avatar.Type => :file
  }
```

## Theme Support

ExAdmin supports 2 themes. The new AdminLte2 theme is enabled by default. The old ActiveAdmin theme is also supported for those that want backward compatibility.

### Changing the Theme

To change the theme to ActiveAdmin, at the following to your `config/config.exs` file:

config/config.exs
```elixir
config :ex_admin,
  theme: ExAdmin.Theme.ActiveAdmin,
  ...
```

### Changing the AdminLte2 Skin Color

The AdminLte2 theme has a number of different skin colors including blue, black, purple, green, red, yellow, blue-light, black-light, purple-light, green-light, red-light, and yellow-light

To change the skin color to, for example, purple:

config/config.exs
```elixir
config :ex_admin,
  skin_color: :purple,
  ...
```

### Enable Theme Selector

You can add a theme selector on the top right of the menu bar by adding the following to your `config/config.exs` file:

config/config.exs
```elixir
config :ex_admin,
  theme_selector: [
    {"AdminLte",  ExAdmin.Theme.AdminLte2},
    {"ActiveAdmin", ExAdmin.Theme.ActiveAdmin}
  ],
  ...
```

### Overriding the model name

You can override the name of a model by defining a `model_name/0` function on
the module. This is useful if you want to use a different module for some of
your actions.

admin/my_model.ex
```elixir
def model_name do
  "custom_name"
end
```

## Authentication

ExAdmin leaves the job of authentication to 3rd party packages. For an example of using [Coherence](https://github.com/smpallen99/coherence) checkout the [Contact Demo Project](https://github.com/smpallen99/contact_demo).

Visit the [Wiki](https://github.com/smpallen99/ex_admin/wiki/Add-authentication) for more information on adding Authentication.

## Contributing

We appreciate any contribution to ExAdmin. Check our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) and [CONTRIBUTING.md](CONTRIBUTING.md) guides for more information. We usually keep a list of features and bugs [in the issue tracker][1].

## References

* Detailed Example [ExAdmin Demo](https://github.com/smpallen99/ex_admin_demo)
* For a brief tutorial, please visit [Elixir Survey Tutorial](https://github.com/smpallen99/elixir_survey_tutorial)
* [Live Demo](http://demo.exadmin.info/admin)
* [Docs](https://hexdocs.pm/ex_admin/)

  [1]: https://github.com/smpallen99/ex_admin/issues
  [2]: http://groups.google.com/group/exadmin-talk

## License

`ex_admin` is Copyright (c) 2015-2016 E-MetroTel

The source code is released under the MIT License.

Check [LICENSE](LICENSE) for more information.
