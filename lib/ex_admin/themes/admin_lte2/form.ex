defmodule ExAdmin.Theme.AdminLte2.Form do
  import Kernel, except: [div: 2]
  import Xain
  import ExAdmin.Utils 
  import ExAdmin.ViewHelpers
  import ExAdmin.Form
  require Integer
  import ExAdmin.Helpers

  @doc false
  def build_form(conn, resource, items, params, script_block) do
    mode = if params[:id], do: :edit, else: :new
    markup do
      model_name = model_name resource
      action = get_action(conn, resource, mode)
      # scripts = ""
      div ".box.box-primary" do
        div ".box-header.with-border" do
          h3 ".box-title" do
            text "New Product"
          end
        end
        Xain.form "accept-charset": "UTF-8", action: "#{action}", class: "form-horizontal", 
            id: "new_#{model_name}", method: :post, enctype: "multipart/form-data", novalidate: :novalidate  do

          resource = setup_resource(resource, params, model_name)

          build_hidden_block(conn, mode)
          div ".box-body" do
            scripts = build_main_block(conn, resource, model_name, items) 
            |> build_scripts
          end
          build_actions_block(conn, model_name, mode) 
        end 
      end
      put_script_block(scripts)
      put_script_block(script_block)
    end
  end
end
