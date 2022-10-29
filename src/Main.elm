port module Main exposing (main)

import Api exposing (AccessToken, UserId)
import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import Http
import Json.Decode exposing (Decoder)


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- curl 'https://piwvahjfjjuzzrfniwcw.supabase.co/rest/v1/Tasks' \
-- -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBpd3ZhaGpmamp1enpyZm5pd2N3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjY2NTg3NDksImV4cCI6MTk4MjIzNDc0OX0.JWqbRoYtHhfsQ0F3i1D-11nkO7kwUgo9EqaCHiq4Ct0" \
-- -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBpd3ZhaGpmamp1enpyZm5pd2N3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjY2NTg3NDksImV4cCI6MTk4MjIzNDc0OX0.JWqbRoYtHhfsQ0F3i1D-11nkO7kwUgo9EqaCHiq4Ct0"


type Model
    = Authenticated AuthenticatedModel
    | Unauthenticated { email : String, password : String }


type alias AuthenticatedModel =
    { tasks : List Task
    , recentlyCompleted : List Task
    , totalCompleted : Int
    , newTaskSummary : String
    , newTaskDescription : String
    , accessToken : AccessToken
    , userId : UserId
    }


type alias Task =
    { summary : String
    , description : String
    , completed : Bool
    }


decodeTask : Decoder Task
decodeTask =
    Json.Decode.map3 Task
        (Json.Decode.field "summary" Json.Decode.string)
        (Json.Decode.field "description" Json.Decode.string)
        (Json.Decode.field "completed" Json.Decode.bool)


init : () -> ( Model, Cmd Msg )
init () =
    ( Unauthenticated { email = "", password = "" }
      -- , Api.get
      --     { url = "Tasks"
      --     , expect = Http.expectJson GetTasksResponse (Json.Decode.list decodeTask)
      --     }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


port toggleDialog : String -> Cmd msg


type Msg
    = AuthenticatedMsg AuthMsg
    | GotEmail String
    | GotPassword String
    | Signup
    | LoginRequested { email : String, password : String }
    | LoginResponse (Result Http.Error ( AccessToken, UserId, Cmd Msg ))


type AuthMsg
    = NoOp
    | GotNewTaskSummary String
    | GotNewTaskDescription String
    | CreateTask
    | MarkComplete
    | RequestDelete
    | ConfirmDelete
    | CancelDelete
      -- | PostTaskResponse (Result Http.Error Task)
    | GetTasksResponse (Result Http.Error (List Task))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( AuthenticatedMsg authMsg, Authenticated authModel ) ->
            updateAuthenticated authMsg authModel
                |> Tuple.mapBoth
                    Authenticated
                    (Cmd.map AuthenticatedMsg)

        ( GotEmail email, Unauthenticated unauthModel ) ->
            ( Unauthenticated { unauthModel | email = email }, Cmd.none )

        ( GotPassword password, Unauthenticated unauthModel ) ->
            ( Unauthenticated { unauthModel | password = password }, Cmd.none )

        ( LoginRequested form, Unauthenticated unauthModel ) ->
            ( Unauthenticated unauthModel
            , Api.signin
                { email = form.email
                , password = form.password
                , expect = LoginResponse
                }
            )

        ( LoginResponse (Err _), _ ) ->
            Debug.todo "login error"

        ( LoginResponse (Ok ( accessToken, userId, refreshCmd )), Authenticated authModel ) ->
            ( Authenticated { authModel | accessToken = accessToken, userId = userId }, refreshCmd )

        ( LoginResponse (Ok ( accessToken, userId, refreshCmd )), Unauthenticated _ ) ->
            ( Authenticated
                { tasks = []
                , recentlyCompleted = []
                , totalCompleted = 0
                , newTaskSummary = ""
                , newTaskDescription = ""
                , accessToken = accessToken
                , userId = userId
                }
            , refreshCmd
            )

        _ ->
            Debug.todo ""


updateAuthenticated : AuthMsg -> AuthenticatedModel -> ( AuthenticatedModel, Cmd AuthMsg )
updateAuthenticated msg model =
    case msg of
        NoOp ->
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
                    , completed = False
                    }
            in
            ( { model
                | newTaskSummary = ""
                , newTaskDescription = ""
                , tasks = model.tasks ++ [ newTask ]
              }
              -- , Api.post
              --     { url = "Tasks"
              --     , expect = Http.expectJson PostTaskResponse
              --     }
            , Debug.todo ""
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

        GetTasksResponse (Err _) ->
            ( model, Cmd.none )

        GetTasksResponse (Ok tasks) ->
            ( { model | tasks = tasks }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "Get It Done!"
    , body =
        case model of
            Unauthenticated unauthModel ->
                viewUnauth unauthModel

            Authenticated authModel ->
                viewAuth authModel
                    |> List.map (Html.map AuthenticatedMsg)
    }


viewUnauth : { email : String, password : String } -> List (Html Msg)
viewUnauth model =
    [ layout [ width fill, height fill ]
        (column
            [ spacing 16, centerX, centerY ]
            [ Input.email
                []
                { placeholder = Nothing
                , label = Input.labelAbove [] (text "Email")
                , text = model.email
                , onChange = GotEmail
                }
            , Input.currentPassword
                []
                { placeholder = Nothing
                , label = Input.labelAbove [] (text "Password")
                , text = model.password
                , onChange = GotPassword
                , show = False
                }
            , Input.button
                []
                { label = text "Signin"
                , onPress =
                    if String.isEmpty model.email || String.isEmpty model.password then
                        Nothing

                    else
                        Just (LoginRequested model)
                }
            ]
        )
    ]


viewAuth : AuthenticatedModel -> List (Html.Html AuthMsg)
viewAuth model =
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


viewModel : AuthenticatedModel -> Element AuthMsg
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


viewCurrentTask : Task -> Element AuthMsg
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


viewTask : Task -> Element AuthMsg
viewTask task =
    text task.summary
        |> el
            [ Font.underline
            , Border.width 1
            , paddingXY 8 4
            , width fill
            ]
