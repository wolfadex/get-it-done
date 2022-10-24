port module Main exposing (main)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { tasks : List Task
    , recentlyCompleted : List Task
    , totalCompleted : Int
    , newTaskSummary : String
    , newTaskDescription : String
    }


type alias Task =
    { summary : String
    , description : String
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( { tasks = []
      , recentlyCompleted = []
      , totalCompleted = 0
      , newTaskSummary = ""
      , newTaskDescription = ""
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


port toggleDialog : String -> Cmd msg


type Msg
    = NoOp
    | GotNewTaskSummary String
    | GotNewTaskDescription String
    | CreateTask
    | MarkComplete
    | RequestDelete
    | ConfirmDelete
    | CancelDelete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotNewTaskSummary summary ->
            ( { model | newTaskSummary = summary }, Cmd.none )

        GotNewTaskDescription description ->
            ( { model | newTaskDescription = description }, Cmd.none )

        CreateTask ->
            ( { model
                | newTaskSummary = ""
                , newTaskDescription = ""
                , tasks =
                    model.tasks
                        ++ [ { summary = model.newTaskSummary
                             , description = model.newTaskDescription
                             }
                           ]
              }
            , Cmd.none
            )

        MarkComplete ->
            case model.tasks of
                [] ->
                    ( model, Cmd.none )

                first :: rest ->
                    ( { model
                        | tasks = rest
                        , recentlyCompleted =
                            (first :: model.recentlyCompleted)
                                |> List.take 50
                        , totalCompleted = model.totalCompleted + 1
                      }
                    , Cmd.none
                    )

        RequestDelete ->
            ( model, toggleDialog "confirm-delete-modal" )

        CancelDelete ->
            ( model, toggleDialog "confirm-delete-modal" )

        ConfirmDelete ->
            ( { model | tasks = List.drop 1 model.tasks }
            , toggleDialog "confirm-delete-modal"
            )


view : Model -> Browser.Document Msg
view model =
    { title = "Get It Done!"
    , body =
        [ layout [ padding 16 ] (viewModel model)
        , Html.node "dialog"
            [ Html.Attributes.id "confirm-delete-modal" ]
            [ column []
                [ text "Delete?"
                , Input.button
                    []
                    { label = text "Cancel"
                    , onPress = Just CancelDelete
                    }
                , Input.button
                    []
                    { label = text "Delete"
                    , onPress = Just ConfirmDelete
                    }
                ]
                |> layoutWith { options = [ noStaticStyleSheet ] } []
            ]
        ]
    }


viewModel : Model -> Element Msg
viewModel model =
    column
        [ spacing 16 ]
        [ text "Get It Done!"
        , column
            [ spacing 8
            , padding 16
            , Border.width 1
            , Border.rounded 4
            ]
            [ Input.text
                []
                { label = Input.labelAbove [] (text "Summary")
                , placeholder = Nothing
                , text = model.newTaskSummary
                , onChange = GotNewTaskSummary
                }
            , Input.multiline
                []
                { label = Input.labelAbove [] (text "Description")
                , spellcheck = True
                , placeholder = Nothing
                , text = model.newTaskDescription
                , onChange = GotNewTaskDescription
                }
            , Input.button
                []
                { label = text "Add task"
                , onPress =
                    if String.isEmpty model.newTaskSummary then
                        Nothing

                    else
                        Just CreateTask
                }
            ]
        , case model.tasks of
            [] ->
                text "Do whatever!"

            current :: rest ->
                column
                    [ spacing 16, width fill ]
                    [ viewCurrentTask current
                    , rest
                        |> List.take 3
                        |> List.map viewTask
                        |> column [ spacing 8, width fill ]
                    ]
        ]


viewCurrentTask : Task -> Element Msg
viewCurrentTask task =
    row
        [ Border.width 1
        , paddingXY 16 8
        , width fill
        ]
        [ column
            [ spacing 8
            , width fill
            ]
            [ text task.summary
                |> el [ Font.underline ]
            , text task.description
            ]
        , column
            []
            [ Input.button
                []
                { label = text "Complete"
                , onPress = Just MarkComplete
                }
            , Input.button
                []
                { label = text "Delete"
                , onPress = Just RequestDelete
                }
            ]
        ]


viewTask : Task -> Element Msg
viewTask task =
    text task.summary
        |> el
            [ Font.underline
            , Border.width 1
            , paddingXY 8 4
            , width fill
            ]
