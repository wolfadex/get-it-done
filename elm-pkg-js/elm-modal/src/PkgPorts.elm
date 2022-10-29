port module PkgPorts exposing (..)


ports =
    { wolfadex_open_modal_to_js = wolfadex_open_modal_to_js
    , wolfadex_close_modal_to_js = wolfadex_close_modal_to_js
    }


port wolfadex_open_modal_to_js : String -> Cmd msg


port wolfadex_close_modal_to_js : String -> Cmd msg