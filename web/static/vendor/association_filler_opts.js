window.ExAdmin = window.ExAdmin || {}
window.ExAdmin.association_filler_opts = {
  placeholder: "Start typing...",
  minimumInputLength: 1,
  delay: 250,
  ajax: {
    datatype: 'json',
    data: function (params) {
      return {
        per_page: 10,
        page: params.page,
        keywords: params.term
      };
    },
    processResults: function (data, params) {
      return {
        results: data.results,
        pagination: {
          more: data.more
        }
      };
    }
  },
  templateResult: function (resource) {
    return resource.pretty_name;
  },
  templateSelection: function (resource) {
    return resource.pretty_name;
  }
}

$(document).ready(function() {
  $("select.select2").select2();
});
