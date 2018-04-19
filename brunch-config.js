exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: {
        'js/admin_lte2.js': [
          "web/static/vendor/themes/admin_lte2/bootstrap/js/bootstrap.min.js",
          "web/static/vendor/themes/admin_lte2/plugins/daterangepicker/daterangepicker.js",
          "web/static/vendor/themes/admin_lte2/plugins/datepicker/bootstrap-datepicker.js",
          "web/static/vendor/themes/admin_lte2/plugins/slimScroll/jquery.slimscroll.min.js",
          "web/static/vendor/themes/admin_lte2/plugins/fastclick/fastclick.min.js",
          "web/static/vendor/themes/admin_lte2/js/ex_admin.js",
          "web/static/vendor/themes/admin_lte2/js/moment.js",
          "web/static/vendor/themes/admin_lte2/dist/js/app.js",
        ],
        'js/jquery.min.js': [
          "web/static/vendor/jQuery-2.1.4.min.js",
          "web/static/vendor/jquery-ui.min.js",
        ],
        'js/ex_admin_common.js': [
          "web/static/vendor/active_admin.js",
          /^(web\/static\/vendor\/active_admin\/)/,
          "web/static/vendor/best_in_place.js",
          "web/static/vendor/best_in_place.purr.js",
          "web/static/vendor/jquery-ujs.js.js",
          "web/static/vendor/themes/admin_lte2/plugins/select2/select2.js",
          "web/static/vendor/association_filler_opts.js",
        ]
      }
    },
    //   // To use a separate vendor.js bundle, specify two files path
    //   // https://github.com/brunch/brunch/blob/stable/docs/config.md#files
    //   // joinTo: {
    //   //  'js/app.js': /^(web\/static\/js)/,
    //   //  'js/vendor.js': /^(web\/static\/vendor)/
    //   // }
    //   //
    //   // To change the order of concatenation of files, explictly mention here
    //   // https://github.com/brunch/brunch/tree/master/docs#concatenation
    //   // order: {
    //   //   before: [
    //   //     'web/static/vendor/js/jquery-2.1.1.js',
    //   //     'web/static/vendor/js/bootstrap.min.js'
    //   //   ]
    //   // }
    // },
    stylesheets: {
      joinTo: { "css/admin_lte2.css": [
        "web/static/vendor/themes/admin_lte2/css/ex_admin.css",
        "web/static/vendor/themes/admin_lte2/bootstrap/css/bootstrap.min.css",
        "web/static/vendor/themes/admin_lte2/dist/css/AdminLTE.min.css",
        "web/static/vendor/themes/admin_lte2/dist/css/skins/all-skins.min.css",
        "web/static/vendor/themes/admin_lte2/css/font-awesome.min.css",
        "web/static/vendor/themes/admin_lte2/css/ionicons.min.css",
        "web/static/vendor/themes/admin_lte2/plugins/datepicker/datepicker3.css",
        "web/static/vendor/themes/admin_lte2/plugins/daterangepicker/daterangepicker-bs3.css",
        "web/static/vendor/themes/admin_lte2/plugins/select2/select2.css",
      ],
      "css/active_admin.css.css": [
        "web/static/vendor/themes/active_admin/css/active_admin.css.css",
        "web/static/vendor/themes/admin_lte2/plugins/select2/select2.css",
      ]
    }
    },
    // templates: {
    //   joinTo: 'js/active_admin.js'
    // }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to '/web/static/assets'. Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(web\/static\/assets)/
  },

  // Phoenix paths configuration
  paths: {
    // Which directories to watch
    watched: ["web/static", "web/static/js", "test/static"],

    // Where to compile files to
    // public: "priv/static"
    public: "priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/^(web\/static\/vendor)/]
    },
    coffeescript: {
      bare: true
    }
  }
};
