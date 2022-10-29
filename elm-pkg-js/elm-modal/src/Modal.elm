module Modal exposing (..)

import Html
import Html.Attributes


{-| Provides access to opening and closing a native modal

@docs open
@docs close
@docs view

-}
type alias PkgPorts ports msg =
    { ports
        | wolfadex_open_modal_to_js : String -> Cmd msg
        , wolfadex_close_modal_to_js : String -> Cmd msg
    }


{-| Open a modal by ID
import Modal
import PkgPorts exposing (ports)
-- In your update function
update msg model =
case msg of
SomeMsg ->
( model, Modal.open ports "id of modal" )
-}
open : PkgPorts a msg -> String -> Cmd msg
open ports =
    ports.wolfadex_open_modal_to_js


{-| Close a modal by ID
import Modal
import PkgPorts exposing (ports)
-- In your update function
update msg model =
case msg of
SomeMsg ->
( model, Modal.close ports "id of modal" )
-}
close : PkgPorts a msg -> String -> Cmd msg
close ports =
    ports.wolfadex_open_modal_to_js


{-| Display a modal
import Modal
-- In your update function
view model =
Modal.view "id of modal" [][ -- content here
]
-}
view : String -> List (Html.Attribute msg) -> List (Html.Html msg) -> Html.Html msg
view id attributes children =
    Html.node "dialog"
        (attributes ++ [ Html.Attributes.id id ])
        children
