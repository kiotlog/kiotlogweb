module Views.Devices exposing (viewDevices, viewDevice, addDevice)

import Html exposing (..)
import Html.Attributes exposing (id, href, class, type_, style, for, attribute, value, selected)
import Html.Events exposing (onClick, onInput, on)
import Http
import Types exposing (..)
import RemoteData exposing (WebData)
import Table exposing (Config, stringColumn, intColumn, defaultCustomizations, Status(..), HtmlDetails, customConfig, veryCustomColumn)
import Json.Decode as JD
import Utils exposing (stringFromInt)


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
                ([ h2 [ class "mdc-layout-grid__cell--span-12 text-center" ]
                    [ text "Sensors" ]
                 ]
                    ++ (List.indexedMap (addDeviceShowSensors model.sensorTypes model.conversions) model.newDevice.sensors)
                )
            , div [ class "mdc-layout-grid__inner padding-vertical-gutter" ]
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
    div [ class "new-device-sensor mdc-card mdc-layout-grid__cell--span-12" ]
        [ div [] [ text ("IDX: " ++ (stringFromInt idx)) ]
        , div [ class "mdc-layout-grid__inner padding-gutter" ]
            [ div
                [ class "mdc-text-field mdc-layout-grid__cell--span-5"
                , attribute "data-mdc-auto-init" "MDCTextField"
                ]
                [ input
                    [ type_ "text"
                    , id ("new_device_new_sensor-name" ++ (stringFromInt idx))
                    , class "mdc-text-field__input"
                    , onInput (SetSensorNameOnDevice idx)
                    , value (sensor.meta.name)
                    ]
                    []
                , label
                    [ class "mdc-floating-label"
                    , for ("new_device_new_sensor-name" ++ (stringFromInt idx))
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
                    , id ("new_device_new_sensor-description" ++ (stringFromInt idx))
                    , class "mdc-text-field__input"
                    , onInput (SetSensorDescrOnDevice idx)
                    , value (sensor.meta.description)
                    ]
                    []
                , label
                    [ class "mdc-floating-label"
                    , for ("new_device_new_sensor-description" ++ (stringFromInt idx))
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
                        ++ (sensorTypesOptions sensorTypes sensor.sensorTypeId)
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
                        ++ (conversionsOptions conversions sensor.conversionId)
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
                    [ option [ selected (sensor.fmt.fmtChr == "") ] []
                    , option [ value "b", selected (sensor.fmt.fmtChr == "b") ] [ text "signed char" ]
                    , option [ value "B", selected (sensor.fmt.fmtChr == "B") ] [ text "unsigned char" ]
                    , option [ value "h", selected (sensor.fmt.fmtChr == "h") ] [ text "short" ]
                    , option [ value "H", selected (sensor.fmt.fmtChr == "H") ] [ text "unsigned short" ]
                    , option [ value "i", selected (sensor.fmt.fmtChr == "i") ] [ text "int" ]
                    , option [ value "I", selected (sensor.fmt.fmtChr == "I") ] [ text "unsigned int" ]
                    , option [ value "l", selected (sensor.fmt.fmtChr == "l") ] [ text "long" ]
                    , option [ value "L", selected (sensor.fmt.fmtChr == "L") ] [ text "unsigned long" ]
                    , option [ value "q", selected (sensor.fmt.fmtChr == "q") ] [ text "long long" ]
                    , option [ value "Q", selected (sensor.fmt.fmtChr == "Q") ] [ text "unsigned long long" ]
                    ]
                , label [ class "mdc-floating-label" ]
                    [ text "Format" ]
                , div [ class "mdc-line-ripple" ] []
                ]
            ]
        , div [ class "mdc-card__actions" ]
            [ div [ class "mdc-card__action-icons" ]
                [ button
                    [ class "mdc-button mdc-card__action mdc-card__action--button"
                    , onClick (RemoveSensorOnDevice idx)
                    ]
                    [ i [ class "material-icons" ] [ text "delete" ]
                    , text "Remove"
                    ]
                ]
            ]
        ]


sensorTypesOptions : WebData (List SensorType) -> String -> List (Html Msg)
sensorTypesOptions st slctd =
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
                    option [ value sType.id, selected (sType.id == slctd) ]
                        [ text sType.name ]
            in
                List.map opt sTypes

        RemoteData.Failure httpError ->
            [ option []
                [ text ("error" ++ (createErrorMessage httpError)) ]
            ]


conversionsOptions : WebData (List Conversion) -> String -> List (Html Msg)
conversionsOptions conv slctd =
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
                    option [ value sType.id, selected (sType.id == slctd) ]
                        [ text sType.fun ]
            in
                List.map opt sTypes

        RemoteData.Failure httpError ->
            [ option []
                [ text ("error" ++ (createErrorMessage httpError)) ]
            ]
