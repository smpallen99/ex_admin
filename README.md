# ExAdmin

[![Build Status](https://travis-ci.org/smpallen99/ex_admin.png?branch=master)](https://travis-ci.org/smpallen99/ex_admin) [![Hex Version][hex-img]][hex] [![License][license-img]][license]

[hex-img]: https://img.shields.io/hexpm/v/ex_admin.svg
[hex]: https://hex.pm/packages/ex_admin
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

Note: This version has been updated to support both Ecto 1.1 and Ecto 2.0. See [Installation](#installation) for more information.

ExAdmin is an auto administration package for [Elixir](http://elixir-lang.org/) and the [Phoenix Framework](http://www.phoenixframework.org/), a port/inspiration of [ActiveAdmin](http://activeadmin.info/) for Elixir.

Checkout the [Live Demo](http://demo.exadmin.info/admin). The source code can be found at [ExAdmin Demo](https://github.com/smpallen99/ex_admin_demo).

Checkout this [Additional Live Demo](http://demo2.exadmin.info/admin) for examples of many-to-many relationships, nested attributes, and authentication.

See the [docs](https://hexdocs.pm/ex_admin/) and the [Wiki](https://github.com/smpallen99/ex_admin/wiki) for more information.

## Usage

ExAdmin is an add on for an application using the [Phoenix Framework](http://www.phoenixframework.org) to create an CRUD administration tool with little or no code. By running a few mix tasks to define which Ecto Models you want to administer, you will have something that works with no additional code.

Before using ExAdmin, you will need a Phoenix project and an Ecto model created.

![ExAdmin](http://exadmin.info/doc/ex_admin_blue.png)

### Installation

Add ex_admin to your deps:

#### Hex

mix.exs
```elixir
  defp deps do
     ...
     {:ex_admin, "~> 0.7"},
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

#### GitHub with Ecto 1.1

mix.exs
```elixir
  defp deps do
     ...
     {:ex_admin, github: "smpallen99/ex_admin"},
     {:phoenix_ecto, "~> 2.0.0", override: true}, # the override is necessary
     {:ecto, "~> 1.1", override: true},           # the override is necessary
     ...
  end
```

Add some admin configuration and the admin modules to the config file

config/config.exs
```elixir
config :ex_admin,
  repo: MyProject.Repo,
  module: MyProject,
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
    admin_routes
  end
```

Add the paging configuration

lib/survey/repo.ex
```elixir
  defmodule MyProject.Repo do
    use Ecto.Repo, otp_app: :survey
    use Scrivener, page_size: 10
  end

```

Add the `priv/static/themes` directory in the `endpoint.ex` file.

lib/my_app/endpoint.ex
```elixir
  ...
  plug Plug.Static,
    at: "/", from: :nested, gzip: false,
    only: ~w(css fonts images js themes favicon.ico robots.txt)
                                 ------

```

Remove or comment `priv/static` in .gitignore to  track `priv/static` directory

.gitignore
```
...
# Since we are building assets from web/static,
# we ignore priv/static. You may want to comment
# this depending on your deployment strategy.
# /priv/static/
```

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

### Customizing the index page

Use the `index do` command to define the fields to be displayed.

admin/my_model.ex
```elixir
defmodule MyProject.ExAdmin.MyModel do
  use ExAdmin.Register
  register_resource MyProject.MyModel do

    index do
      selectable_column

      column :id
      column :name
      actions       # display the default actions column
    end
  end
end
```

### Customizing the form

The following example shows how to customize the form with the `form` macro:

```
defmodule MyProject.ExAdmin.Contact do
  use ExAdmin.Register

  register_resource MyProject.Contact do
    form contact do
      inputs do
        input contact, :first_name
        input contact, :last_name
        input contact, :email
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
defmodule Survey.ExAdmin.Question do
  use ExAdmin.Register

  register_resource Survey.Question do
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
