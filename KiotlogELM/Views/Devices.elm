module Views.Devices exposing (viewDevices, viewDevice, addDevice)

import Html exposing (..)
import Html.Attributes exposing (id, href, class, type_, style, for, attribute, value)
import Html.Events exposing (onClick, onInput, on)
import Http
import Types exposing (..)
import RemoteData exposing (WebData)
import Table exposing (Config, stringColumn, intColumn, defaultCustomizations, Status(..), HtmlDetails, customConfig, veryCustomColumn)
import Json.Decode as JD


viewDevices : Model -> Html Msg
viewDevices model =
    case model.devices of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            div [ class "kiotlog-page text-center" ]
                [ h1 []
                    [ text "Loading..." ]
                ]

        RemoteData.Success devices ->
            devicesTable devices (model.devicesTable)

        RemoteData.Failure httpError ->
            viewError "Couldn't fetch devices at this time." (createErrorMessage httpError)


viewDevice : Model -> Html Msg
viewDevice model =
    case model.device of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            h3 [] [ text "Loading..." ]

        RemoteData.Success device ->
            deviceCards device

        RemoteData.Failure httpError ->
            viewError "Couldn't fetch device." (createErrorMessage httpError)


viewError : String -> String -> Html Msg
viewError errorHeading errorMessage =
    div [ class "kiotlog-page text-center" ]
        [ h3 [] [ text errorHeading ]
        , text errorMessage
        ]


devicesTable : List Device -> Table.State -> Html Msg
devicesTable devices tableState =
    div [ class "kiotlog-page" ]
        [ div [ class "mdc-layout-grid padding-0" ]
            [ div [ class "mdc-layout-grid__inner" ]
                [ h1 [ class "mdc-layout-grid__cell--span-6 margin-0" ]
                    [ text "Devices" ]
                , h1 [ class "text-right mdc-layout-grid__cell--span-6 margin-0" ]
                    [ button
                        [ type_ "button"
                        , onClick FetchDevices
                        , attribute "data-mdc-auto-init" "MDCRipple"
                        , class "mdc-button"
                        ]
                        [ i [ class "material-icons" ]
                            [ text "refresh" ]
                        ]
                    , a
                        [ href "#/devices/new"
                        , attribute "data-mdc-auto-init" "MDCRipple"
                        , class "mdc-button mdc-button--unelevated"
                        ]
                        [ i [ class "material-icons" ]
                            [ text "add" ]
                        ]
                    ]
                ]
            ]
        , Table.view config tableState devices
        ]


mapSensors : Sensor -> Html Msg
mapSensors sensor =
    div []
        [ text sensor.meta.name ]


deviceCards : Device -> Html Msg
deviceCards device =
    div [ class "kiotlog-page mdc-layout-grid" ]
        [ div [ class "mdc-layout-grid__inner" ]
            [ div [ class "mdc-card padding-20 mdc-layout-grid__cell--span-6" ]
                [ h3 []
                    [ text ("Device Id: " ++ device.device) ]
                , p []
                    [ text ("Name: " ++ device.meta.name) ]
                ]
            , div
                [ class "mdc-card padding-20 mdc-layout-grid__cell--span-6" ]
                [ h3 []
                    [ text "Sensors" ]
                , div []
                    (List.map
                        mapSensors
                        device.sensors
                    )
                ]
            ]
        ]


config : Table.Config Device Msg
config =
    customConfig
        { toId = .id
        , toMsg = SetDevicesTableState
        , columns =
            [ Table.stringColumn "Id" .id
            , Table.stringColumn "Device" .device
            , detailsColumn
            ]
        , customizations =
            { defaultCustomizations
                | tableAttrs = [ class "devices-list" ]
                , thead = simpleThead

                -- | rowAttrs = toRowAttrs
                -- , tbodyAttrs = [ class "mdc-layout-grid" ]
            }
        }


detailsColumn : Table.Column Device Msg
detailsColumn =
    veryCustomColumn
        { name = ""
        , viewData = showDeviceLink
        , sorter = Table.unsortable
        }


showDeviceLink : Device -> HtmlDetails Msg
showDeviceLink { id } =
    HtmlDetails []
        [ a
            [ href ("#/devices/" ++ id)
            , class "mdc-button"
            , attribute "data-mdc-auto-init" "MDCRipple"
            ]
            [ text "show" ]
        ]


simpleThead : List ( String, Status, Attribute msg ) -> HtmlDetails msg
simpleThead headers =
    HtmlDetails [] (List.map simpleTheadHelp headers)


simpleTheadHelp : ( String, Status, Attribute msg ) -> Html msg
simpleTheadHelp ( name, status, onClick ) =
    let
        content =
            case status of
                Unsortable ->
                    [ text name ]

                Sortable selected ->
                    [ if selected then
                        darkGrey "arrow_downward"
                      else
                        lightGrey "arrow_downward"
                    , text name
                    ]

                Reversible Nothing ->
                    [ lightGrey "sort"
                    , text name
                    ]

                Reversible (Just isReversed) ->
                    [ darkGrey
                        (if isReversed then
                            "arrow_upward"
                         else
                            "arrow_downward"
                        )
                    , text name
                    ]
    in
        th [ onClick ] content


darkGrey : String -> Html msg
darkGrey symbol =
    i [ style [ ( "color", "#555" ) ], class "material-icons" ] [ text symbol ]


lightGrey : String -> Html msg
lightGrey symbol =
    i [ style [ ( "color", "#ccc" ) ], class "material-icons" ] [ text symbol ]



-- toRowAttrs : Device -> List (Attribute Msg)
-- toRowAttrs device =
--     [ class "mdc-layout-grid__inner"
--     ]
-- tHeadAttrs : ( String, Status, Attribute msg ) -> Html msg
-- tHeadAttrs ( name, status, onClick ) =
--     HtmlDetails [] (List.map simpleTheadHelp headers)
-- viewTableHeader : Html Msg
-- viewTableHeader =
--     tr []
--         [ th []
--             [ text "ID" ]
--         , th []
--             [ text "Title" ]
--         , th []
--             []
--         ]


createErrorMessage : Http.Error -> String
createErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "It appears you don't have an Internet connection right now."

        Http.BadStatus response ->
            response.status.message

        Http.BadPayload message response ->
            message


addDevice : Model -> Html Msg
addDevice model =
    div [ class "kiotlog-page" ]
        [ div [ class "mdc-layout-grid padding-0" ]
            [ div [ class "mdc-layout-grid__inner" ]
                [ h1 [ class "mdc-layout-grid__cell--span-6 margin-0" ]
                    [ text "Add new device" ]
                , h1 [ class "mdc-layout-grid__cell--span-6 margin-0 text-right" ]
                    [ a
                        [ href "#/devices"
                        , class "mdc-button"
                        , attribute "data-mdc-auto-init" "MDCRipple"
                        ]
                        [ i [ class "material-icons mdc-button__icon" ]
                            [ text "arrow_back" ]
                        , text "Back"
                        ]
                    , button
                        [ type_ "button"
                        , class "mdc-button mdc-button--unelevated"
                        , attribute "data-mdc-auto-init" "MDCRipple"
                        , onClick CreateNewDevice
                        ]
                        [ i [ class "material-icons mdc-button__icon" ]
                            [ text "check" ]
                        , text "Add"
                        ]
                    ]
                ]
            ]
        , div [ class "mdc-layout-grid kiotlog-container-small" ]
            [ div [ class "mdc-layout-grid__inner" ]
                [ div
                    [ class "mdc-text-field mdc-layout-grid__cell--span-12"
                    , attribute "data-mdc-auto-init" "MDCTextField"
                    ]
                    [ input
                        [ type_ "text"
                        , id "new_device_device_id"
                        , class "mdc-text-field__input"
                        , onInput NewDeviceDevice
                        ]
                        []
                    , label
                        [ class "mdc-floating-label"
                        , for "new_device_device_id"
                        ]
                        [ text "Device Id" ]
                    , div [ class "mdc-line-ripple" ] []
                    ]
                , div
                    [ class "mdc-text-field mdc-layout-grid__cell--span-12"
                    , attribute "data-mdc-auto-init" "MDCTextField"
                    ]
                    [ input
                        [ type_ "text"
                        , id "new_device_name"
                        , class "mdc-text-field__input"
                        , onInput NewDeviceName
                        ]
                        []
                    , label
                        [ class "mdc-floating-label"
                        , for "new_device_name"
                        ]
                        [ text "Name" ]
                    , div [ class "mdc-line-ripple" ] []
                    ]
                , div
                    [ class "mdc-layout-grid__cell--span-12"
                    , style [ ( "display", "flex" ), ( "flex-direction", "row" ), ( "align-items", "center" ) ]
                    ]
                    [ div [ class "mdc-switch" ]
                        [ input
                            [ type_ "checkbox"
                            , id "new_device_bigendian"
                            , class "mdc-switch__native-control"
                            , attribute "role" "switch"
                            , onClick (NewDeviceBigendian (not model.newDevice.frame.bigendian))
                            ]
                            []
                        , div [ class "mdc-switch__background" ]
                            [ div [ class "mdc-switch__knob" ] []
                            ]
                        ]
                    , label
                        [ for "new_device_bigendian"
                        , class "mdc-switch-label"
                        ]
                        [ text "Bigendian" ]
                    ]
                ]
            , div [ class "mdc-layout-grid__inner" ]
                [ h2 [ class "mdc-layout-grid__cell--span-12 text-center" ]
                    [ text "Sensors"
                    ]
                , div [ class "mdc-layout-grid__cell--span-12" ]
                    (List.indexedMap (addDeviceShowSensors model.sensorTypes model.conversions) model.newDevice.sensors)
                ]
            , div [ class "mdc-layout-grid__inner" ]
                [ button
                    [ class "mdc-button mdc-button--unelevated mdc-layout-grid__cell--span-12"
                    , attribute "data-mdc-auto-init" "MDCRipple"
                    , onClick AddSensor
                    ]
                    [ i [ class "material-icons" ]
                        [ text "add" ]
                    ]
                ]
            ]
        ]


addDeviceShowSensors : WebData (List SensorType) -> WebData (List Conversion) -> Int -> Sensor -> Html Msg
addDeviceShowSensors sensorTypes conversions idx sensor =
    div [ class "new-device-sensor mdc-layout-grid__inner" ]
        [ div
            [ class "mdc-text-field mdc-layout-grid__cell--span-5"
            , attribute "data-mdc-auto-init" "MDCTextField"
            ]
            [ input
                [ type_ "text"
                , id "new_device_new_sensor-name"
                , class "mdc-text-field__input"
                , onInput (SetSensorNameOnDevice idx)
                ]
                []
            , label
                [ class "mdc-floating-label"
                , for "new_device_new_sensor-name"
                ]
                [ text "Name" ]
            , div [ class "mdc-line-ripple" ] []
            ]
        , div
            [ class "mdc-text-field mdc-layout-grid__cell--span-7"
            , attribute "data-mdc-auto-init" "MDCTextField"
            ]
            [ input
                [ type_ "text"
                , id "new_device_new_sensor-description"
                , class "mdc-text-field__input"
                , onInput (SetSensorDescrOnDevice idx)
                ]
                []
            , label
                [ class "mdc-floating-label"
                , for "new_device_new_sensor-description"
                ]
                [ text "Description" ]
            , div [ class "mdc-line-ripple" ] []
            ]
        , div
            [ class "mdc-select mdc-layout-grid__cell--span-5"
            , attribute "data-mdc-auto-init" "MDCSelect"
            , on "change" (JD.map (SetSensorTypeOnDevice idx) Html.Events.targetValue)
            ]
            [ select [ class "mdc-select__native-control" ]
                ([ option [] [] ]
                    ++ (sensorTypesOptions sensorTypes)
                )
            , label [ class "mdc-floating-label" ]
                [ text "Sensor Type" ]
            , div [ class "mdc-line-ripple" ] []
            ]
        , div
            [ class "mdc-select mdc-layout-grid__cell--span-4"
            , attribute "data-mdc-auto-init" "MDCSelect"
            , on "change" (JD.map (SetSensorConversionOnDevice idx) Html.Events.targetValue)
            ]
            [ select [ class "mdc-select__native-control" ]
                ([ option [] [] ]
                    ++ (conversionsOptions conversions)
                )
            , label [ class "mdc-floating-label" ]
                [ text "Conversion" ]
            , div [ class "mdc-line-ripple" ] []
            ]
        , div
            [ class "mdc-select mdc-layout-grid__cell--span-3"
            , attribute "data-mdc-auto-init" "MDCSelect"
            , on "change" (JD.map (SetSensorFmtChrOnDevice idx) Html.Events.targetValue)
            ]
            [ select [ class "mdc-select__native-control" ]
                [ option [] []
                , option [ value "b" ] [ text "signed char" ]
                , option [ value "B" ] [ text "unsigned char" ]
                , option [ value "h" ] [ text "short" ]
                , option [ value "H" ] [ text "unsigned short" ]
                , option [ value "i" ] [ text "int" ]
                , option [ value "I" ] [ text "unsigned int" ]
                , option [ value "l" ] [ text "long" ]
                , option [ value "L" ] [ text "unsigned long" ]
                , option [ value "q" ] [ text "long long" ]
                , option [ value "Q" ] [ text "unsigned long long" ]
                ]
            , label [ class "mdc-floating-label" ]
                [ text "Conversion" ]
            , div [ class "mdc-line-ripple" ] []
            ]
        ]


sensorTypesOptions : WebData (List SensorType) -> List (Html Msg)
sensorTypesOptions st =
    case st of
        RemoteData.NotAsked ->
            [ option []
                [ text "..." ]
            ]

        RemoteData.Loading ->
            [ option []
                [ text "Loading ..." ]
            ]

        RemoteData.Success sTypes ->
            let
                opt sType =
                    option [ value sType.id ]
                        [ text sType.name ]
            in
                List.map opt sTypes

        RemoteData.Failure httpError ->
            [ option []
                [ text ("error" ++ (createErrorMessage httpError)) ]
            ]


conversionsOptions : WebData (List Conversion) -> List (Html Msg)
conversionsOptions conv =
    case conv of
        RemoteData.NotAsked ->
            [ option []
                [ text "..." ]
            ]

        RemoteData.Loading ->
            [ option []
                [ text "Loading ..." ]
            ]

        RemoteData.Success sTypes ->
            let
                opt sType =
                    option [ value sType.id ]
                        [ text sType.fun ]
            in
                List.map opt sTypes

        RemoteData.Failure httpError ->
            [ option []
                [ text ("error" ++ (createErrorMessage httpError)) ]
            ]