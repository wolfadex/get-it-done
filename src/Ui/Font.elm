module Ui.Font exposing (..)

import Html
import Html.Attributes


underline : Html.Attribute msg
underline =
    Html.Attributes.style "text-underline-position" "auto"
