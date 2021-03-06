﻿(*
    Copyright (C) 2017 Giampaolo Mancini, Trampoline SRL.
    Copyright (C) 2017 Francesco Varano, Trampoline SRL.

    This file is part of Kiotlog.

    Kiotlog is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Kiotlog is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*)

module Kiotlog.Web.API

open Suave
open Suave.Logging
open Suave.Filters
open Suave.Operators
open Suave.CORS
open Suave.Successful

open Arguments
open Kiotlog.Web.Authentication

[<EntryPoint>]
let main argv =

    let config = parseCLI argv
    let cs = config.PostgresConnectionString
    let apiKey = config.ApiKey

    let logger = Targets.create Verbose [||]

    let cors =
        cors {defaultCORSConfig with allowedMethods = InclusiveOption.Some [HttpMethod.GET; HttpMethod.POST; HttpMethod.PUT; HttpMethod.PATCH; HttpMethod.DELETE]}

    let app =
        cors >=> choose [
            OPTIONS >=> OK "CORS"
            authenticate apiKey (
                choose [
                    Webparts.Devices.webPart cs
                    Webparts.SensorTypes.webPart cs
                    Webparts.Sensors.webPart cs
                    Webparts.Conversions.webPart cs
                    Webparts.Status.webPart cs
                    Webparts.Annotations.webPart cs
                ]
            )
            RequestErrors.NOT_FOUND "Found no handlers"
        ] >=> logStructured logger logFormatStructured

    let conf =
        { defaultConfig with
            bindings =
                [
                    HttpBinding.createSimple HTTP config.HttpHost config.HttpPort
                ]
        }
    startWebServer conf app

    0 // return an integer exit code
