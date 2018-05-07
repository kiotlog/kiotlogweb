module Routing exposing (..)

import Navigation exposing (Location)
import UrlParser exposing (..)
import Types exposing (..)


extractRoute : Location -> Route
extractRoute location =
    case (parsePath matchRoute location) of
        Just route ->
            route

        Nothing ->
            NotFoundRoute


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map DashboardRoute top
        , map DevicesRoute (s "devices")
        , map DeviceRoute (s "devices" </> string)
        ]
