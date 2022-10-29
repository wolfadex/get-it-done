exports.init = function (app) {
  app.ports.wolfadex_open_modal_to_js.subscribe(function (id) {
    requestAnimationFrame(function () {
      try {
        const dialog = document.getElementById(id);

        dialog.showModal();
      } catch (err) {
        // TODO: log this somehwere relevant
      }
    });
  });

  app.ports.wolfadex_close_modal_to_js.subscribe(function (id) {
    requestAnimationFrame(function () {
      try {
        const dialog = document.getElementById(id);

        dialog.close();
      } catch (err) {
        // TODO: log this somehwere relevant
      }
    });
  });
};
