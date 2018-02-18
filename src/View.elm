module View exposing (..)

import Css exposing (..)
import Data.Commit as Commit exposing (Commit, Meta)
import Date exposing (Date, Month(..))
import Html.Styled as Html exposing (Html, styled)
import Html.Styled.Attributes as Attr
import Markdown


theme =
    { border = border3 (px 1) solid (hex "#888888")
    , borderColor = hex "#888888"
    , borderRadius = px 3
    , width = (px 800)
    }


pageTitle =
    styled Html.h1
        [ margin2 (px 20) auto
        , width theme.width
        ]


renderHeader : { a | commits : List Commit, toasts : List String } -> List (Html msg)
renderHeader model =
    [ pageTitle []
        [ Html.text
            ("Interesting Commits to Elm | showing " ++ toString (List.length model.commits))
        ]
    , if List.isEmpty model.toasts then
        Html.text ""
      else
        Html.ul [] (List.map (renderToast >> Html.li []) model.toasts)
    ]


renderToast : String -> List (Html msg)
renderToast toast =
    [ Html.text toast
    ]


renderElmVersion : Meta -> Html msg
renderElmVersion meta =
    if meta.elm_0_19_design then
        elmVersionLabel []
            [ Html.text "Elm 0.19"
            ]
    else if meta.elm_0_18_design then
        elmVersionLabel []
            [ Html.text "Elm 0.18"
            ]
    else if meta.elm_0_17_design then
        elmVersionLabel []
            [ Html.text "Elm 0.17"
            ]
    else if meta.elm_0_16_design then
        elmVersionLabel []
            [ Html.text "Elm 0.16"
            ]
    else if meta.elm_0_15_design then
        elmVersionLabel []
            [ Html.text "Elm 0.15"
            ]
    else if meta.elm_0_14_design then
        elmVersionLabel []
            [ Html.text "Elm 0.14"
            ]
    else
        elmVersionLabel []
            [ Html.text "Ancient"
            ]


elmVersionLabel =
    styled Html.span
        [ theme.border
        , backgroundColor (hex "#eeeeee")
        , borderRadius theme.borderRadius
        , display inlineBlock
        , float right
        , margin2 zero (px 4)
        , padding2 (px 2) (px 4)
        ]


repoNameLabel =
    styled Html.span
        [ theme.border
        , backgroundColor (hex "#eeeeee")
        , borderRadius theme.borderRadius
        , display inlineBlock
        , margin2 zero (px 4)
        , padding2 (px 2) (px 4)
        ]


commitLink =
    styled Html.a
        [ color (rgb 96 181 204)
        , display inlineBlock
        , marginRight (px 4)
        , textDecoration underline
        ]


commitList =
    styled Html.ul
        [ listStyle none
        , margin zero
        , padding zero
        ]


commitSummary =
    styled Html.span
        [ fontWeight bold
        ]


makeCommitUrl commit =
    commit.repoUrl ++ "/commit/" ++ commit.sha


renderCommitList commits =
    [ commitList []
        (commits
            |> List.indexedMap (renderCommit (List.length commits))
        )
    ]

authorName =
    styled Html.span
        [ display inlineBlock
        , fontStyle italic
        ]

commitItem =
    styled Html.li
        [ theme.border
        , backgroundColor (hex "#ffffff")
        , borderRadius theme.borderRadius
        , boxShadow4 zero (px 1) (px 3) (hex "#aaaaaa")
        , margin2 (px 20) auto
        , paddingBottom (px 10)
        , width theme.width
        ]


commitHeader =
    styled Html.div
        [ backgroundColor (hex "#f5f5f5")
        , borderBottom3 (px 1) solid theme.borderColor
        , borderTopLeftRadius theme.borderRadius
        , borderTopRightRadius theme.borderRadius
        , paddingBottom (px 10)
        , paddingLeft (px 10)
        , paddingRight (px 10)
        , paddingTop (px 10)
        ]


commitContent =
    styled Html.div
        [ paddingLeft (px 10)
        , paddingRight (px 10)
        , paddingTop (px 10)
        ]


commitBody =
    styled Html.div
        [
        ]


serialNumber all index =
    let
        allLength = String.length (toString all)
        serial = String.padLeft allLength '0' (toString (index + 1))
    in
    styled Html.span
        [ display inlineBlock
        , fontFamilies [ "Monospace", "sans-serif" ]
        , paddingRight (px 8)
        ]
        []
        [ Html.text ("#" ++ serial ++ "/" ++ toString all)
        ]


renderCommit : Int -> Int -> Commit -> Html msg
renderCommit all index commit =
    commitItem []
        [ commitHeader []
            [ serialNumber all index
            , commitLink
                [ Attr.href (makeCommitUrl commit)
                , Attr.title (makeCommitUrl commit)
                ]
                [ Html.text (renderDate commit.date)
                ]
            , repoNameLabel []
                [ Html.text commit.repoName
                ]
            , authorName [] [ Html.text commit.authorName ]
            , renderElmVersion commit.meta
            ]
        , commitContent []
            [ commitSummary []
                [ Html.text commit.summary ]
            , commitBody []
                [ Markdown.toHtml [] commit.body |> Html.fromUnstyled
                ]
            ]
        ]


pageFrame =
    styled Html.div
        []


withCssReset : List (Html msg) -> Html msg
withCssReset content =
    pageFrame []
        (Html.node "style"
            []
            [ Html.text
                """
html {
    box-sizing: border-box;
    height: 100%;
}
body {
    font-family: 'Roboto', sans-serif;
    font-size: 16px;
    height: 100%;
}
*, *:before, *:after {
    box-sizing: inherit;
}
              """
            ]
            :: Html.node "link"
                 [ Attr.href "https://fonts.googleapis.com/css?family=Roboto"
                 , Attr.rel "stylesheet"
                 ]
                 []
            :: content
        )


mapMonth month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


renderDate : Date -> String
renderDate date =
    let
        year =
            String.padLeft 4 '0' (toString (Date.year date))

        month =
            String.padLeft 2 '0' (toString (mapMonth (Date.month date)))

        day =
            String.padLeft 2 '0' (toString (Date.day date))

        hour =
            String.padLeft 2 '0' (toString (Date.hour date))

        min =
            String.padLeft 2 '0' (toString (Date.minute date))
    in
    year ++ "-" ++ month ++ "-" ++ day ++ " " ++ hour ++ ":" ++ min

