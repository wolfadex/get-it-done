module Extra.Dict exposing (..)

import Dict exposing (Dict)


mapAt : comparable -> (a -> a) -> Dict comparable a -> Dict comparable a
mapAt key fn dict =
    Dict.update key
        (\maybeValue ->
            case maybeValue of
                Nothing ->
                    Nothing

                Just value ->
                    Just (fn value)
        )
        dict
