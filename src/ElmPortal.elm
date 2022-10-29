module ElmPortal exposing (..)

import Html exposing (Html)
import Html.Attributes


carl =
    "Carl"



-- view options =
--     Html.node "elm-portal"
--         [ Html.Attributes.attribute "portal-target-id" ]
--         [ Html.div
--             [ Html.Attributes.style "position" "fixed"
--             , Html.Attributes.style "left" (String.fromFloat x ++ "px")
--             , Html.Attributes.style "top" (String.fromFloat y ++ "px")
--             ]
--             [ options.content ]
--         ]
-- decodeClick : k -> Bool -> (Msg k -> msg) -> Decoder msg
-- decodeClick did isOpen toMsg =
--     if isOpen then
--         JD.succeed (toMsg (Close did))
--     else
--         JD.map2
--             (\x y -> toMsg (Open did { x = x, y = y }))
--             (JD.at [ "currentTarget", "___getBoundingClientRect", "left" ] JD.float)
--             (JD.at [ "currentTarget", "___getBoundingClientRect", "bottom" ] JD.float)
