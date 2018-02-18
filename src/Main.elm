module Main exposing (main)

import Data.Commit as Commit exposing (Commit)
import Html
import Html.Styled as Styled exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as Styled
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        filterCommit commit =
            commit.meta.mightBeInteresting
    in
    case msg of
        CommitsReceived (Ok allCommits) ->
            let
                interesting =
                    List.filter filterCommit allCommits
            in
            ( { model | commits = interesting }, Cmd.none )

        CommitsReceived (Err err) ->
            ( { model | toasts = toString err :: model.toasts }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        header = View.renderHeader model
        lastUpdated =
            model.commits
                |> List.reverse
                |> List.head
                |> Maybe.map .date
        abstract =
            [ View.abstract []
                [ View.text
                    """
                    This page shows all commits to Elm core package repositories
                    that may contain interesting thoughts and decisions regarding the
                    design process of the Elm language. Note that this is not a live
                    list but is sporadically generated and served statically.
                    """
                , case lastUpdated of
                      Just timestamp ->
                          View.text ("Last tracked commit timestamp is " ++ View.renderDate timestamp)

                      Nothing ->
                          View.empty
                ]
            ]
        footer =
            [ View.renderFooter []
                [ View.text "View powered by Elm"
                , View.footerLink
                    [ Attr.href "https://github.com/mfeineis/elm-design-insights"
                    ]
                    [ View.text "https://github.com/mfeineis/elm-design-insights"
                    ]
                ]
            ]
        commitList =
            if List.isEmpty model.commits then
                [ View.spinner []
                    [ View.text "Please stand by, this might take a moment..."
                    ]
                ]
            else
                View.renderCommitList model.commits
    in
    View.withCssReset
        (header ++ abstract ++ footer ++ commitList)
