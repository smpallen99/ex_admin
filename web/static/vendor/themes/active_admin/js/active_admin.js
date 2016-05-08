//= require active_admin/base
//= require jquery
//= require jquery-ui
//= require jquery-migrate-1.1.1

// TODO: move this to a file provided by ace_contacts plugin
function serializeCategories() {
  var categoryIds = $.makeArray(
    $("table.index_table .category").map(function() {
      return $(this).data('id');
    })
  );
  return {ids: categoryIds};
};

$(document).ready(function(){
  // Activating Best In Place
  jQuery(".best_in_place").best_in_place();
  //$('table.index_table tbody').sortable();
  $('#backup-now').click(function(){
    $('#title_bar').after("<div class='flashes'><div class='flash flash_info'>Creating backup. This may take a while ...</div></div>");
    return true;
  });
  $('.restore-link').click(function(e){
    if (e.isPropagationStopped()) {
      $('#title_bar').after("<div class='flashes'><div class='flash flash_info'>Restoring backup. This may take a while ...</div></div>");
    }
    return true;
  });
  $('body.admin_categories table.index_table tbody').sortable({
    update: function(){
      $.ajax({
        url: '/admin/categories/sort',
        type: 'post',
        data: serializeCategories(),
        complete: function(){
          $('.paginated_collection').effect('highlight');
        }
      });
    }
  });
});
