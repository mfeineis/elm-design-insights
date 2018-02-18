module Main exposing (main)

import Data.Commit as Commit exposing (Commit)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Json.Decode as Decode
import Markdown


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
        , view = view
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        request =
            Http.get "/dist/result-latest.json" (Decode.list Commit.decoder)
    in
    ( { commits = []
      , toasts = []
      }
    , Http.send CommitsReceived request
    )


filterCommit : Commit -> Bool
filterCommit commit =
    commit.meta.mightBeInteresting && commit.meta.elm_0_19_design
    --commit.meta.mightBeInteresting || commit.meta.elm_0_19_design


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
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
        commits =
            model.commits
                |> List.map renderCommit
    in
    withCssReset
        (renderHeader model ++ commits)


renderHeader : Model -> List (Html Msg)
renderHeader model =
    [ Html.text ("Some header (" ++ toString (List.length model.commits) ++ ")")
    , Html.ul [] (List.map (renderToast >> Html.li []) model.toasts)
    ]


renderToast toast =
    [ Html.text toast
    ]


renderDate =
    toString 

renderElmVersion { elm_0_19_design }=
    if elm_0_19_design then
        Html.text "0.19"
    else
        Html.text ""


renderCommit : Commit -> Html Msg
renderCommit commit =
    Html.li []
        [ Html.div []
            [ Html.text (renderDate commit.date)
            , Html.text commit.sha
            , Html.text commit.repoName
            , Html.text commit.authorName
            , renderElmVersion commit.meta
            ]
        , Html.div []
            [ Html.b []
                [ Html.text commit.summary ]
            , Html.div []
                [ Markdown.toHtml [] commit.body
                ]
            ]
        ]


withCssReset : List (Html Msg) -> Html Msg
withCssReset content =
    Html.div []
        (Html.node "style"
            []
            [ Html.text
                """
html {
    box-sizing: border-box;
    height: 100%;
}
body {
    font-size: 16px;
    height: 100%;
}
*, *:before, *:after {
    box-sizing: inherit;
}
              """
            ]
            :: content
        )
