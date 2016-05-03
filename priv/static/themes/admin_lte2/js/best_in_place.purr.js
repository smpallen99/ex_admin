//= require jquery.purr

jQuery(document).on('best_in_place:error', function(event, request, error) {
    // Display all error messages from server side validation
    jQuery.each(jQuery.parseJSON(request.responseText), function(index, value) {
      if( typeof(value) == "object") {value = index + " " + value.toString(); }
      var container = jQuery("<span class='flash-error'></span>").html(value);
      container.purr();
    });
});
