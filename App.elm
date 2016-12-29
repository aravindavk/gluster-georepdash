module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (class, title)
import Http
import Json.Decode as Json exposing (field)
import WebSocket


serverName : String
serverName =
    "f241:5000"

main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


eventsServer : String
eventsServer =
    "ws://" ++ serverName ++ "/events"


apply : Json.Decoder (a -> b) -> Json.Decoder a -> Json.Decoder b
apply func value =
    Json.map2 (<|) func value



-- MODEL


type alias StatusRow =
    { status : String
    , checkpoint_time : String
    , slave : String
    , slave_user : String
    , mastervol : String
    , last_synced : String
    , checkpoint_completed : String
    , master_brick : String
    , master_node : String
    , slavevol : String
    , slave_node : String
    , master_node_uuid : String
    , crawl_status : String
    , checkpoint_completion_time : String
    , entry : String
    , data : String
    , meta : String
    , failures : String
    }


type alias Session =
    List StatusRow


type alias Model =
    { data : List Session
    }


init : ( Model, Cmd Msg )
init =
    ( Model []
    , getGeorepStatus
    )



-- UPDATE


type Msg
    = NewMessage String
    | FetchHandle (Result Http.Error (List Session))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchHandle (Ok md) ->
            ( Model md, Cmd.none )

        FetchHandle(Err _) ->
            ( model, Cmd.none )

        NewMessage msg ->
            if msg == "get" then
                ( model, getGeorepStatus )
            else
                ( model, Cmd.none )



-- VIEW


viewStatusRow : StatusRow -> Html Msg
viewStatusRow st_row =
    let
        status_bg =
            if st_row.status == "Active" then
                "green"
            else if st_row.status == "Faulty" then
                "red"
            else if st_row.status == "Offline" then
                "gray"
            else
                "default"
    in
        tr [ class ("status-row-" ++ status_bg) ]
            [ td [] [ text st_row.master_node ]
            , td [] [ text st_row.master_brick ]
            , td [] [ text st_row.slave_node ]
            , td [] [ text st_row.status ]
            , td [] [ text st_row.crawl_status ]
            , td [] [ text st_row.last_synced ]
            , td [] [ text st_row.checkpoint_time ]
            , td [] [ text st_row.checkpoint_completed ]
            , td [] [ text st_row.checkpoint_completion_time ]
            ]


getValueOrEmpty : Maybe StatusRow -> String
getValueOrEmpty inp =
    case inp of
        Just x ->
            x.mastervol

        Nothing ->
            ""


viewSession : Session -> Html Msg
viewSession sess =
    let
        num_active =
            List.length (List.filter (\n -> n.status == "Active") sess)

        num_passive =
            List.length (List.filter (\n -> n.status == "Passive") sess)

        num_faulty =
            List.length (List.filter (\n -> n.status == "Faulty") sess)

        num_offline =
            List.length (List.filter (\n -> n.status == "Offline") sess)

        num_created =
            List.length (List.filter (\n -> n.status == "Created") sess)

        num_stopped =
            List.length (List.filter (\n -> n.status == "Stopped") sess)

        num_paused =
            List.length (List.filter (\n -> n.status == "Paused") sess)

        master_vol =
            case (List.head sess) of
                Just x ->
                    x.mastervol

                Nothing ->
                    ""

        slave =
            case (List.head sess) of
                Just x ->
                    x.slave

                Nothing ->
                    ""

    in
        div [ class "session-container" ]
            [ div [ class "session-heading" ] [ text (master_vol ++ " -> " ++ slave) ]
            , table [ class "pure-table pure-table-horizontal" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "Master Node" ]
                        , th [] [ text "Master Brick" ]
                        , th [] [ text "Slave Node" ]
                        , th [] [ text "Status" ]
                        , th [] [ text "Crawl Status" ]
                        , th [] [ text "Last Synced" ]
                        , th [] [ text "Checkpoint Time" ]
                        , th [] [ text "Checkpoint Completed" ]
                        , th [] [ text "Checkpoint Completion Time" ]
                        ]
                    ]
                , tbody [] (List.map viewStatusRow sess)
                ]
            , span [ class "summary-line" ]
                [ text
                    ("Faulty: "
                        ++ (toString num_faulty)
                        ++ " Active: "
                        ++ (toString num_active)
                        ++ " Paused: "
                        ++ (toString num_paused)
                        ++ " Created: "
                        ++ (toString num_created)
                        ++ " Stopped: "
                        ++ (toString num_stopped)
                        ++ " Offline: "
                        ++ (toString num_offline)
                    )
                ]
            ]


view : Model -> Html Msg
view model =
    div [ class "container" ] (List.map viewSession model.data)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen eventsServer NewMessage



-- HTTP


getGeorepStatus : Cmd Msg
getGeorepStatus =
    let
        url =
            "http://" ++ serverName ++ "/get"
    in
        Http.send FetchHandle (Http.get url decodeGeorepStatusData)



-- JSON Decoding


statusRowDecoder =
    apply (apply (apply (apply (apply (apply (apply (apply (apply (apply (apply (apply (apply (apply (apply (apply (apply (Json.map StatusRow (field "status" Json.string)) (field "checkpoint_time" Json.string)) (field "slave" Json.string)) (field "slave_user" Json.string)) (field "mastervol" Json.string)) (field "last_synced" Json.string)) (field "checkpoint_completed" Json.string)) (field "master_brick" Json.string)) (field "master_node" Json.string)) (field "slavevol" Json.string)) (field "slave_node" Json.string)) (field "master_node_uuid" Json.string)) (field "crawl_status" Json.string)) (field "checkpoint_completion_time" Json.string)) (field "entry" Json.string)) (field "data" Json.string)) (field "meta" Json.string)) (field "failures" Json.string)


decodeGeorepStatusData : Json.Decoder (List Session)
decodeGeorepStatusData =
    Json.list (Json.list statusRowDecoder)
