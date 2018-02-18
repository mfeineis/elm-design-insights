module Main exposing (main)

import Data.Commit as Commit exposing (Commit)
import Html
import Html.Styled as Styled exposing (Html)
import Http
import View


type alias Flags =
    {}


type Msg
    = CommitsReceived (Result Http.Error (List Commit))


type alias Model =
    { commits : List Commit
    , toasts : List String
    }


main : Program Never Model Msg
main =
    Html.program
        { init = init {}
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view >> Styled.toUnstyled
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { commits = []
      , toasts = []
      }
    , Http.send CommitsReceived
        (Http.get "/dist/result-latest.json" Commit.listDecoder)
    )


filterCommit : Commit -> Bool
filterCommit commit =
    True
    --commit.meta.mightBeInteresting && commit.meta.elm_0_19_design


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CommitsReceived (Ok allCommits) ->
            let
                interesting =
                    List.filter filterCommit allCommits
                        --|> List.take 20
            in
            ( { model | commits = interesting }, Cmd.none )

        CommitsReceived (Err err) ->
            ( { model | toasts = toString err :: model.toasts }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        header = View.renderHeader model
        commitList =
            View.renderCommitList model.commits
    in
    View.withCssReset
        (header ++ commitList)
