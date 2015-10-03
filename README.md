ExAdmin
=======

ExAdmin is a port/inspiration of [ActiveAdmin](http://activeadmin.info/) for Elixir. 

ExAdmin is an auto administration package for [Elixir](http://elixir-lang.org/) and the [Phoenix Framework](http://www.phoenixframework.org/) 

Documentation is coming soon. 

For a brief tutorial, please visit [Elixir Survey Tutorial](https://github.com/smpallen99/elixir_survey_tutorial)

## Usage

ExAdmin is an add on for an application using the [Phoenix Framework](http://www.phoenixframework.org) to create an CRUD administration tool with little or no code. By running a few mix tasks to define which Ecto Models you want to administer, you will have something that works with no additional code. 

Before using ExAdmin, you will need a Phoenix project and an Ecto model created. 

### Installation

Add ex_admin to your deps:

mix.exs
```elixir
  defp deps do
     ...
     {:ex_admin, github: "smpallen99/ex_admin"}, 
     ...
  end
```

Fetch and compile the dependency

```mix do deps.get, compile```

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
  # setup the ExAdmin routes
  admin_routes :admin

  scope "/", MyProject do
  ...
```

Add the paging configuration

lib/survey/repo.ex
```elixir
  defmodule MyProject.Repo do
    use Ecto.Repo, otp_app: :survey
    use Scrivener, page_size: 10
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

Start the application with `iex -S mix phoenix.server`

Visit http://localhost:4000/admin

You should be the default Dashboard page. 

To add a model, use `admin.gen.resource model` mix task

```
mix admin.gen.resource MyModel

Add the new module to the config file:

```elixir
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

Start the phoenix server again and browse to `http://localhost:4000/admin/my_model

You can now list/add/edit/and delete MyModels

## Getting Started


## License

`ex_admin` is Copyright (c) 2015 E-MetroTel

The source code is released under the MIT License.

Check [LICENSE](LICENSE) for more information.
