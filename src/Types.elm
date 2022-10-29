module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Random
import Time
import UUID
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , tasks : Dict Uuid ClientTask
    , recentlyCompleted : List Task
    , totalCompleted : Int
    , newTaskSummary : String
    , newTaskDescription : String
    , localId : Int
    , toMaybeDelete : Maybe Uuid
    }


type ClientTask
    = Unsaved Task
    | Saved Task


type alias Task =
    { summary : String
    , description : String
    , completedAt : Maybe Time.Posix
    }


type alias Uuid =
    String


type alias BackendModel =
    { uuidSeeds : UUID.Seeds
    , tasks : Dict Uuid Task
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | GotNewTaskSummary String
    | GotNewTaskDescription String
    | CreateTask
    | MarkComplete Uuid
    | RequestDelete Uuid
    | ConfirmDelete (Maybe Uuid)
    | CancelDelete
    | MarkTaskCompleteRequested Uuid
    | MarkTaskCompleteAtRequested Uuid Time.Posix
    | MarkTaskUncompleteRequested Uuid


type ToBackend
    = NoOpToBackend
    | SaveNewTaskRequested Uuid Task
    | SaveTaskRequested Uuid Task
    | GetCurrentTasksRequested


type BackendMsg
    = NoOpBackendMsg
    | RandomSeedRecieved Random.Seed


type ToFrontend
    = NoOpToFrontend
    | TaskCreated { tempUuid : Uuid, actualUuid : Uuid, task : Task }
      -- | TaskSaved Uuid Task
    | GetCurrentTasksResponse (Dict Uuid ClientTask)
