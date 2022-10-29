module Api exposing
    ( AccessToken
    , UserId
    , get
    , post
    , signin
    , signup
    )

import Env
import Http
import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Process
import Task exposing (Task)


type UserId
    = UserId String


type AccessToken
    = AccessToken String


request :
    AccessToken
    ->
        { method : String
        , url : String
        , body : Http.Body
        , expect : Http.Expect msg
        }
    -> Cmd msg
request (AccessToken accessToken) options =
    Http.request
        { method = options.method
        , headers =
            [ Http.header "Authorization" ("Bearer " ++ accessToken)

            -- , Http.header "apikey" accessToken
            ]
        , url = Env.baseUrl ++ "rest/v1/" ++ options.url
        , body = options.body
        , expect = options.expect
        , timeout = Nothing
        , tracker = Nothing
        }


get : AccessToken -> { url : String, expect : Http.Expect msg } -> Cmd msg
get accessToken options =
    request accessToken
        { method = "GET"
        , url = Env.baseUrl ++ "rest/v1/" ++ options.url
        , body = Http.emptyBody
        , expect = options.expect
        }


post : AccessToken -> { url : String, expect : Http.Expect msg, body : Value } -> Cmd msg
post accessToken options =
    request accessToken
        { method = "POST"
        , url = Env.baseUrl ++ "rest/v1/" ++ options.url
        , body = Http.jsonBody options.body
        , expect = options.expect
        }


signup : { email : String, password : String, expect : Result Http.Error UserId -> msg } -> Cmd msg
signup options =
    Http.request
        { method = "POST"
        , headers = [ Http.header "apikey" Env.apiKey ]
        , url = Env.baseUrl ++ "auth/v1/signup"
        , body =
            [ ( "email", Json.Encode.string options.email )
            , ( "password", Json.Encode.string options.password )
            ]
                |> Json.Encode.object
                |> Http.jsonBody
        , expect = Http.expectJson options.expect decodeUser
        , timeout = Nothing
        , tracker = Nothing
        }


decodeUser : Decoder UserId
decodeUser =
    Json.Decode.map UserId
        (Json.Decode.field "id" Json.Decode.string)


type alias SigninExpect msg =
    Result Http.Error ( AccessToken, UserId, Cmd msg ) -> msg


type alias SigninOk msg =
    ( AccessToken, UserId, Cmd msg )


signin : { email : String, password : String, expect : SigninExpect msg } -> Cmd msg
signin options =
    Http.request
        { method = "POST"
        , headers = [ Http.header "apikey" Env.apiKey ]
        , url = Env.baseUrl ++ "auth/v1/token?grant_type=password"
        , body =
            [ ( "email", Json.Encode.string options.email )
            , ( "password", Json.Encode.string options.password )
            ]
                |> Json.Encode.object
                |> Http.jsonBody
        , expect = Http.expectJson options.expect (decodeSignin options.expect)
        , timeout = Nothing
        , tracker = Nothing
        }


decodeSignin : SigninExpect msg -> Decoder (SigninOk msg)
decodeSignin expect =
    Json.Decode.map4
        (\accessToken expiresIn refreshToken userId ->
            ( AccessToken accessToken
            , userId
            , Process.sleep ((expiresIn - 180) * 1000)
                |> Task.andThen
                    (\() ->
                        refreshTask expect refreshToken
                    )
                |> Task.attempt expect
            )
        )
        (Json.Decode.field "access_token" Json.Decode.string)
        (Json.Decode.field "expires_in" Json.Decode.float)
        (Json.Decode.field "refresh_token" Json.Decode.string)
        (Json.Decode.field "user" decodeUser)


refreshTask : SigninExpect msg -> String -> Task Http.Error (SigninOk msg)
refreshTask expect refreshToken =
    Http.task
        { method = "POST"
        , headers =
            [--     Http.header "apikey" apiKey
             -- , Http.header "Authorization" ("Bearer " ++ apiKey)
            ]
        , url = Env.baseUrl ++ "auth/v1/token?grant_type=refresh_token"
        , body =
            [ ( "refresh_token", Json.Encode.string refreshToken )
            ]
                |> Json.Encode.object
                |> Http.jsonBody
        , resolver = Http.stringResolver (resolveRefresh (decodeSignin expect))
        , timeout = Nothing
        }


resolveRefresh : Decoder (SigninOk msg) -> Http.Response String -> Result Http.Error (SigninOk msg)
resolveRefresh decoder response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata _ ->
            Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ _ body ->
            case Json.Decode.decodeString decoder body of
                Err err ->
                    Err (Http.BadBody (Json.Decode.errorToString err))

                Ok data ->
                    Ok data
