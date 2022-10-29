port module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Extra.Dict
import Html
import Lamdera
import Modal
import Task
import Time
import Types exposing (..)
import Ui
import Ui.Border
import Ui.Font
import Ui.Input
import Ui.Layout
import Url


port wolfadex_open_modal_to_js : String -> Cmd msg


port wolfadex_close_modal_to_js : String -> Cmd msg


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \m -> Sub.none
        , view = view
        }


init : Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    ( { key = key
      , tasks = Dict.empty
      , recentlyCompleted = []
      , totalCompleted = 0
      , newTaskSummary = ""
      , newTaskDescription = ""
      , localId = 0
      , toMaybeDelete = Nothing
      }
    , Lamdera.sendToBackend GetCurrentTasksRequested
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            ( model, Cmd.none )

        NoOpFrontendMsg ->
            ( model, Cmd.none )

        GotNewTaskSummary summary ->
            ( { model | newTaskSummary = summary }, Cmd.none )

        GotNewTaskDescription description ->
            ( { model | newTaskDescription = description }, Cmd.none )

        CreateTask ->
            let
                newTask : Task
                newTask =
                    { summary = model.newTaskSummary
                    , description = model.newTaskDescription
                    , completedAt = Nothing
                    }

                tempUuid : String
                tempUuid =
                    String.fromInt model.localId
            in
            ( { model
                | newTaskSummary = ""
                , newTaskDescription = ""
                , tasks = Dict.insert tempUuid (Unsaved newTask) model.tasks
                , localId = model.localId + 1
              }
            , Lamdera.sendToBackend (SaveTaskRequested tempUuid newTask)
            )

        MarkComplete uuid ->
            ( model, Cmd.none )

        RequestDelete uuid ->
            ( { model | toMaybeDelete = Just uuid }
            , wolfadex_open_modal_to_js modalIds.confirmDelete
            )

        ConfirmDelete Nothing ->
            ( model
            , wolfadex_close_modal_to_js modalIds.confirmDelete
            )

        ConfirmDelete (Just uuid) ->
            ( { model | tasks = Dict.remove uuid model.tasks }
            , wolfadex_close_modal_to_js modalIds.confirmDelete
            )

        CancelDelete ->
            ( { model | toMaybeDelete = Nothing }
            , wolfadex_close_modal_to_js modalIds.confirmDelete
            )

        MarkTaskCompleteRequested uuid ->
            ( model
            , Time.now
                |> Task.perform (MarkTaskCompleteAtRequested uuid)
            )

        MarkTaskCompleteAtRequested uuid time ->
            let
                updatedTasks : Dict Uuid ClientTask
                updatedTasks =
                    Extra.Dict.mapAt uuid
                        (\task ->
                            case task of
                                Saved t ->
                                    Saved { t | completedAt = Just time }

                                Unsaved t ->
                                    Unsaved { t | completedAt = Just time }
                        )
                        model.tasks
            in
            -- ( { model | tasks = updatedTasks }
            -- , case Dict.get uuid updatedTasks of
            --     Just task ->
            --         Lamdera.sendToBackend <|
            --             case task of
            --                 Unsaved t ->
            --                     SaveNewTaskRequested uuid t
            --                 Saved t ->
            --                     SaveTaskRequested uuid t
            --        )
            --     Nothing -> Cmd.none
            -- )
            ( { model | tasks = updatedTasks }
            , case Dict.get uuid updatedTasks of
                Nothing ->
                    Cmd.none

                Just task ->
                    Lamdera.sendToBackend <|
                        case task of
                            Unsaved t ->
                                SaveNewTaskRequested uuid t

                            Saved t ->
                                SaveTaskRequested uuid t
            )

        MarkTaskUncompleteRequested uuid ->
            let
                updatedTasks : Dict Uuid ClientTask
                updatedTasks =
                    Extra.Dict.mapAt uuid
                        (\task ->
                            case task of
                                Saved t ->
                                    Saved { t | completedAt = Nothing }

                                Unsaved t ->
                                    Unsaved { t | completedAt = Nothing }
                        )
                        model.tasks
            in
            -- ( { model | tasks = updatedTasks }
            -- , case Dict.get uuid updatedTasks of
            --     Just task ->
            --         Lamdera.sendToBackend <|
            --             case task of
            --                 Unsaved t ->
            --                     SaveNewTaskRequested uuid t
            --                 Saved t ->
            --                     SaveTaskRequested uuid t
            --        )
            --     Nothing -> Cmd.none
            -- )
            Debug.todo ""


modalIds :
    { confirmDelete : String
    }
modalIds =
    { confirmDelete = "confirm-delete-modal"
    }


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )

        TaskCreated response ->
            ( { model
                | tasks =
                    model.tasks
                        |> Dict.remove response.tempUuid
                        |> Dict.insert response.actualUuid (Saved response.task)
              }
            , Cmd.none
            )

        GetCurrentTasksResponse tasks ->
            ( { model | tasks = Dict.union tasks model.tasks }, Cmd.none )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Get it Done!"
    , body =
        [ viewModel model
        , Modal.view modalIds.confirmDelete
            []
            [ Ui.column []
                [ Ui.text [] "Delete?"
                , Ui.Input.button
                    []
                    { content = Ui.text [] "Cancel"
                    , onPress = Just CancelDelete
                    }
                , Ui.Input.button
                    []
                    { content = Ui.text [] "Delete"
                    , onPress = Just (ConfirmDelete model.toMaybeDelete)
                    }
                ]
            ]
        ]
    }


viewModel : FrontendModel -> Html.Html FrontendMsg
viewModel model =
    Ui.column
        [ Ui.Layout.gap 1
        , Ui.Layout.padding 1
        ]
        [ Ui.text [] "Get It Done!"
        , Ui.column
            [ Ui.Layout.gap 0.5
            , Ui.Layout.padding 1
            , Ui.Border.width 1
            , Ui.Border.radius 0.25
            , Ui.Layout.shrinkWidth
            ]
            [ Ui.Input.text
                { label = Ui.text [] "Summary"
                , onChange = GotNewTaskSummary
                , attributes = []
                }
                model.newTaskSummary
            , Ui.Input.multilineText
                { label = Ui.text [] "Description"
                , onChange = GotNewTaskDescription
                , attributes = []
                }
                model.newTaskDescription
            , Ui.Input.button
                [ Ui.Layout.shrinkWidth ]
                { content = Ui.text [] "Add task"
                , onPress =
                    if String.isEmpty model.newTaskSummary then
                        Nothing

                    else
                        Just CreateTask
                }
            ]
        , case Dict.toList model.tasks of
            [] ->
                Ui.text [] "Do whatever!"

            current :: rest ->
                Ui.column
                    [ Ui.Layout.gap 1
                    ]
                    [ viewCurrentTask current
                    , rest
                        |> List.take 3
                        |> List.map viewTask
                        |> Ui.column
                            [ Ui.Layout.gap 0.5
                            ]
                    ]
        ]


viewCurrentTask : ( Uuid, ClientTask ) -> Html.Html FrontendMsg
viewCurrentTask ( uuid, clientTask ) =
    let
        task =
            case clientTask of
                Unsaved t ->
                    t

                Saved t ->
                    t
    in
    Ui.row
        [ Ui.Border.width 1
        , Ui.Layout.paddingXY 1 0.5
        ]
        [ Ui.column
            [ Ui.Layout.gap 0.5
            ]
            [ Ui.text [ Ui.Font.underline ] task.summary
            , Ui.text [] task.description
            ]
        , Ui.column
            []
            [ Ui.Input.button
                []
                { content = Ui.text [] "Complete"
                , onPress = Just (MarkComplete uuid)
                }
            , Ui.Input.button
                []
                { content = Ui.text [] "Delete"
                , onPress = Just (RequestDelete uuid)
                }
            ]
        ]


viewTask : ( Uuid, ClientTask ) -> Html.Html FrontendMsg
viewTask ( uuid, clientTask ) =
    let
        task =
            case clientTask of
                Unsaved t ->
                    t

                Saved t ->
                    t
    in
    Ui.text
        [ Ui.Font.underline
        , Ui.Border.width 1
        , Ui.Layout.paddingXY 0.5 0.25
        ]
        task.summary
