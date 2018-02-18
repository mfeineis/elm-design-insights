module Data.Commit exposing (Commit, decoder)

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder, Value)


type alias Meta =
    { byPivotalAuthor : Bool
    --, elm_0_13_design : Bool
    --, elm_0_14_design : Bool
    --, elm_0_15_design : Bool
    --, elm_0_16_design : Bool
    --, elm_0_17_design : Bool
    --, elm_0_18_design : Bool
    , elm_0_19_design : Bool
    , isAncient : Bool
    , mightBeInteresting : Bool
    }


decodeMaybeBool : String -> Decoder Bool
decodeMaybeBool name =
    (Decode.maybe (Decode.field name Decode.bool))
        |> Decode.andThen (Maybe.withDefault False >> Decode.succeed)


decodeMeta : Decoder Meta
decodeMeta =
    Decode.map4 Meta
        (Decode.field "byPivotalAuthor" Decode.bool)
        (Decode.field "elm_0_19_design" Decode.bool)
        (Decode.field "isAncient" Decode.bool)
        (decodeMaybeBool "mightBeInteresting")


type alias Commit =
    { authorName : String
    --, authorEmail : String
    --, authorInfo : String
    , body : String
    , date : Date
    , meta : Meta
    , repoName : String
    , repoUrl : String
    , sha : String
    , summary : String
    }


decodeBody : Decoder String
decodeBody =
    (Decode.maybe (Decode.field "body" Decode.string))
        |> Decode.andThen (Maybe.withDefault "" >> Decode.succeed)


decodeDate : Decoder Date
decodeDate =
    Decode.string
        |> Decode.andThen
            (\s ->
                case (Date.fromString s) of
                    Ok date ->
                        Decode.succeed date

                    Err reason ->
                        Decode.fail reason
            )

decoder : Decoder Commit
decoder =
    Decode.map8 Commit
        --( Decode.field "authorEmail" Decode.string )
        ( Decode.field "authorName" Decode.string )
        --( Decode.field "authorInfo" Decode.string )
        ( decodeBody )
        ( Decode.field "date" decodeDate )
        ( Decode.field "meta" decodeMeta )
        ( Decode.field "repoName" Decode.string )
        ( Decode.field "repoUrl" Decode.string )
        ( Decode.field "sha" Decode.string )
        ( Decode.field "summary" Decode.string )
