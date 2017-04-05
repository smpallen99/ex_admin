$(document).ready(function() {
  // Fix sortable helper
  var fixHelper = function(e, ui) {
    ui.children().each(function() {
        $(this).width($(this).width());
    });
    return ui;
  };

  $('table.sortable').ready(function(){
    var td_count = $(this).find('tbody tr:first-child td').length
    $('table.sortable tbody').sortable(
      {
        handle: '.handle',
        helper: fixHelper,
        placeholder: 'ui-sortable-placeholder',
        update: function(event, ui) {
          //$("#progress").show();
          var positions = [];
          $.each($('table.sortable tbody tr'), function(position, obj){
            var reg = /^(\w+_?)_([-0-9a-f]+)$/i;
            var parts = reg.exec($(obj).prop('id'));
            if (parts) {
              positions = positions.concat({'id': parts[2], 'position': position});
            }
          });
          $.ajax({
            url: $(ui.item).closest("table.sortable").data("sortable-link"),
            type: 'POST',
            beforeSend: function(xhr) {
              var csrf_token = $('meta[name=csrf-token]').attr('content');
              xhr.setRequestHeader('x-csrf-token', csrf_token);
            },
            dataType: 'script',
            data: {positions: positions},
            success: function(data){
              //$("#progress").hide();
            }
          });
        },
        start: function (event, ui) {
          // Set correct height for placehoder (from dragged tr)
          ui.placeholder.height(ui.item.height());
          // Fix placeholder content to make it correct width
          ui.placeholder.html("<td colspan='"+(td_count)+"'></td>");
        },
        stop: function (event, ui) {
          // Fix odd/even classes after reorder
          $("table.sortable tr:even").removeClass("odd even").addClass("even");
          $("table.sortable tr:odd").removeClass("odd even").addClass("odd");
        }

      });
  });

});