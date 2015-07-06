$(document).on 'ready page:load', ->

  #
  # Use ActiveAdmin.modal_dialog to prompt user if confirmation is required for current Batch Action
  #
  $('#batch_actions_selector li a').click (e)->
    e.stopPropagation() # prevent Rails UJS click event
    e.preventDefault()
    console.log('clicked it')
    if message = $(@).data 'confirm'
      r = window.confirm(message)
      if r == true
        $(@).trigger 'confirm:complete', $(@).data('inputs')
    else
      $(@).trigger 'confirm:complete'

  $('#batch_actions_selector li a').on 'confirm:complete', (e, inputs) ->
    if val = JSON.stringify inputs
      $('#batch_action_inputs').val val
    else
      $('#batch_action_inputs').attr 'disabled', 'disabled'

    $('#batch_action').val $(@).data 'action'
    $('#collection_selection').submit()

  #
  # Add checkbox selection to resource tables and lists if batch actions are enabled
  #

  if $("#batch_actions_selector").length && $(":checkbox.toggle_all").length

    if $(".paginated_collection").find("table.index_table").length
      $(".paginated_collection table").tableCheckboxToggler()
    else
      $(".paginated_collection").checkboxToggler()

    $(".paginated_collection").find(":checkbox").bind "change", ->
      if $(".paginated_collection").find(":checkbox").filter(":checked").length > 0
        $("#batch_actions_selector").aaDropdownMenu("enable")
      else
        $("#batch_actions_selector").aaDropdownMenu("disable")
