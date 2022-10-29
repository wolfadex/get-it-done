module Ui.Border exposing (..)

import Html
import Html.Attributes


width : Int -> Html.Attribute msg
width amount =
    Html.Attributes.style "border-width" (String.fromInt amount ++ "px")


radius : Float -> Html.Attribute msg
radius amount =
    Html.Attributes.style "border-radius" (String.fromFloat amount ++ "rem")
