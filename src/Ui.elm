module Ui exposing (..)

import Html exposing (Attribute)
import Html.Attributes


type alias Ui msg =
    Html.Html msg


column : List (Attribute msg) -> List (Html.Html msg) -> Html.Html msg
column attributes children =
    Html.div
        ([ Html.Attributes.style "display" "flex"
         , Html.Attributes.style "flex-direction" "column"
         ]
            ++ attributes
        )
        children


row : List (Attribute msg) -> List (Html.Html msg) -> Html.Html msg
row attributes children =
    Html.div
        ([ Html.Attributes.style "display" "flex"
         ]
            ++ attributes
        )
        children


text : List (Attribute msg) -> String -> Html.Html msg
text attributes str =
    Html.span
        attributes
        [ Html.text str ]
