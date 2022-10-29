module Backend exposing (..)

import Dict
import Lamdera exposing (ClientId, SessionId)
import Random
import Types exposing (..)
import UUID


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \_ -> Sub.none
        }


init : ( BackendModel, Cmd BackendMsg )
init =
    let
        badSeed : Random.Seed
        badSeed =
            Random.initialSeed 0
    in
    ( { uuidSeeds =
            { seed1 = badSeed
            , seed2 = badSeed
            , seed3 = badSeed
            , seed4 = badSeed
            }
      , tasks = Dict.empty
      }
    , Random.independentSeed
        |> Random.generate RandomSeedRecieved
    )


update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )

        RandomSeedRecieved seed ->
            let
                ( _, seed1 ) =
                    Random.step (Random.int 0 1) seed

                ( _, seed2 ) =
                    Random.step (Random.int 0 1) seed1

                ( _, seed3 ) =
                    Random.step (Random.int 0 1) seed2

                ( _, seed4 ) =
                    Random.step (Random.int 0 1) seed3
            in
            ( { model
                | uuidSeeds =
                    { seed1 = seed1
                    , seed2 = seed2
                    , seed3 = seed3
                    , seed4 = seed4
                    }
              }
            , Cmd.none
            )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    let
        _ =
            Debug.log "tasks" model.tasks
    in
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )

        SaveNewTaskRequested tempUuid task ->
            let
                ( actualUuid, newUuidSeeds ) =
                    UUID.step model.uuidSeeds
                        |> Tuple.mapFirst (UUID.forName "task")
                        |> Tuple.mapFirst UUID.toString
            in
            ( { model
                | uuidSeeds = newUuidSeeds
                , tasks =
                    Dict.insert actualUuid
                        { summary = task.summary
                        , description = task.description
                        , completedAt = task.completedAt
                        }
                        model.tasks
              }
            , Lamdera.sendToFrontend clientId
                (TaskCreated
                    { tempUuid = tempUuid
                    , actualUuid = actualUuid
                    , task = task
                    }
                )
            )

        SaveTaskRequested uuid task ->
            ( { model
                | tasks = Dict.insert uuid task model.tasks
              }
            , Cmd.none
            )

        GetCurrentTasksRequested ->
            ( model
            , model.tasks
                |> Dict.toList
                |> List.filterMap
                    (\( uuid, task ) ->
                        case task.completedAt of
                            Nothing ->
                                Just
                                    ( uuid
                                    , Saved
                                        { summary = task.summary
                                        , description = task.description
                                        , completedAt = task.completedAt
                                        }
                                    )

                            Just _ ->
                                Nothing
                    )
                |> Dict.fromList
                |> GetCurrentTasksResponse
                |> Lamdera.sendToFrontend clientId
            )
