module Ui.Input exposing (..)

import Html
import Html.Attributes
import Html.Events


text :
    { onChange : String -> msg
    , label : Html.Html msg
    , attributes : List (Html.Attribute msg)
    }
    -> String
    -> Html.Html msg
text config value =
    labeled
        config.label
        [ Html.input
            (config.attributes
                ++ [ Html.Attributes.value value
                   , Html.Events.onInput config.onChange
                   ]
            )
            []
        ]


multilineText :
    { onChange : String -> msg
    , label : Html.Html msg
    , attributes : List (Html.Attribute msg)
    }
    -> String
    -> Html.Html msg
multilineText config value =
    labeled
        config.label
        [ Html.textarea
            (config.attributes
                ++ [ Html.Attributes.value value
                   , Html.Events.onInput config.onChange
                   ]
            )
            []
        ]


button : List (Html.Attribute msg) -> { onPress : Maybe msg, content : Html.Html msg } -> Html.Html msg
button attributes config =
    Html.button
        ([]
            ++ attributes
            ++ [ case config.onPress of
                    Just handler ->
                        Html.Events.onClick handler

                    Nothing ->
                        Html.Attributes.disabled True
               ]
        )
        [ config.content ]



---- INTERNAL


labeled : Html.Html msg -> List (Html.Html msg) -> Html.Html msg
labeled label children =
    Html.label
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "flex-direction" "column"
        ]
        (label :: children)
