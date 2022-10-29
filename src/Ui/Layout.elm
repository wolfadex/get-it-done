module Ui.Layout exposing (..)

import Html exposing (Attribute)
import Html.Attributes


type alias Ui msg =
    Html.Html msg


gap : Float -> Attribute msg
gap amount =
    Html.Attributes.style "gap" (String.fromFloat amount ++ "rem")


padding : Float -> Attribute msg
padding amount =
    Html.Attributes.style "padding" (String.fromFloat amount ++ "rem")


paddingXY : Float -> Float -> Attribute msg
paddingXY x y =
    Html.Attributes.style "padding" (String.fromFloat y ++ "rem" ++ String.fromFloat x ++ "rem")


shrinkWidth : Attribute msg
shrinkWidth =
    Html.Attributes.style "align-self" "flex-start"
