module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  M = env.matcher
  t = env.require('decl-api').types
  Request = require 'request'
  actualUrl = "http://api.wunderground.com/api/{apiKey}/conditions/lang:DL/q/{country}/{state}{city}.json";
  forecastUrl = "http://api.wunderground.com/api/{apiKey}/forecast/lang:DL/q/{country}/{state}{city}.json";

  class WundergroundPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass("WundergroundDevice",{
        configDef : deviceConfigDef.WundergroundDevice,
        createCallback : (config) => new WundergroundDevice(config,this)
      })

      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-wunderground/app/wundergroundTempl-page.coffee"
          mobileFrontend.registerAssetFile 'html', "pimatic-wunderground/app/wundergroundTempl-template.html"
          mobileFrontend.registerAssetFile 'css', "pimatic-wunderground/app/css/wunderground.css"
          mobileFrontend.registerAssetFile 'css', "pimatic-wunderground/app/css/weather-icons.css"
          mobileFrontend.registerAssetFile 'eot', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.eot"
          mobileFrontend.registerAssetFile 'svg', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.svg"
          mobileFrontend.registerAssetFile 'ttf', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.ttf"
          mobileFrontend.registerAssetFile 'woff', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.woff"
          mobileFrontend.registerAssetFile 'woff2', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.woff2"

        return

  class WundergroundDevice extends env.devices.Device
    template: 'wunderground'

    attributes:
      weather:
        description: 'the weather data'
        type: t.string

    constructor: (@config, @plugin) ->
      @id = @config.id
      @name = @config.name
      @apiKey = @config.apiKey
      @country = @config.country
      @state = @config.state
      @city = @config.city
      @days = @config.days
      @weather = ''

      @reloadWeather()

      @timerId = setInterval ( =>
        @reloadWeather()
      ), 300000

      super()

    destroy: () ->
      if @timerId?
        clearInterval @timerId
        @timerId = null
      super()

    getApiKey: -> Promise.resolve(@apiKey)

    setApiKey: (value) ->
      if @apiKey is value then return
      @apiKey = value

    getDays: -> Promise.resolve(@days)

    setDays: (value) ->
      if @days is value then return
      @days = value

    getCountry: -> Promise.resolve(@country)

    setCountry: (value) ->
      if @country is value then return
      @country = value

    getState: -> Promise.resolve(@state)

    setState: (value) ->
      if @state is value then return
      @state = value

    getCity: -> Promise.resolve(@city)

    setCity: (value) ->
      if @city is value then return
      @city = value

    getWeather: -> Promise.resolve(@weather)

    setWeather: (value) ->
      @weather = value
      @emit 'weather', value

    detectIconClass: (icons) ->
      icon = ''

      switch icons
        when 'clear'
          icon = 'wi wi-day-sunny'
        when 'cloudy'
          icon = 'wi wi-day-cloudy'
        when 'flurries'
          icon = 'wi wi-day-sleet'
        when 'fog'
          icon = 'wi wi-day-fog'
        when 'hazy'
          icon = 'wi wi-day-haze'
        when 'mostlycloudy'
          icon = 'wi wi-day-cloudy'
        when 'mostlysunny'
          icon = 'wi wi-day-sunny-overcast'
        when 'sleet'
          icon = 'wi wi-day-sleet'
        when 'rain'
          icon = 'wi wi-day-showers'
        when 'snow'
          icon = 'wi wi-day-snow'
        when 'sunny'
          icon = 'wi wi-day-sunny'
        when 'tstorms'
          icon = 'wi wi-day-thunderstorm'
        when 'unknown'
          icon = 'wi wi-day-thunderstorm'
        when 'partlycloudy'
          icon = 'wi wi-day-cloudy'
        when 'nt_clear'
          icon = 'wi wi-stars'
        when 'nt_cloudy'
          icon = 'wi wi-night-alt-cloudy'
        when 'nt_flurries'
          icon = 'wi wi-night-alt-sleet'
        when 'nt_fog'
          icon = 'wi wi-night-fog'
        when 'nt_hazy'
          icon = 'wi wi-night-haze'
        when 'nt_mostlycloudy'
          icon = 'wi wi-night-cloudy'
        when 'nt_mostlysunny'
          icon = 'wi wi-night-sunny-overcast'
        when 'nt_sleet'
          icon = 'wi wi-night-sleet'
        when 'nt_rain'
          icon = 'wi wi-night-showers'
        when 'nt_snow'
          icon = 'wi wi-night-snow'
        when 'nt_sunny'
          icon = 'wi wi-night-sunny'
        when 'nt_tstorms'
          icon = 'wi wi-night-thunderstorm'
        when 'nt_unknown'
          icon = 'wi wi-night-thunderstorm'
        when 'nt_partlycloudy'
          icon = 'wi wi-night-cloudy'

      return icon

    reloadWeather: ->
      url = actualUrl.replace('{apiKey}', @apiKey).replace('{country}', @country).replace('{city}', @city)
      if @state? and @state.length > 0
        url = url.replace('{state}', @state + '/')
      else
        url = url.replace('{state}', '')

      Request.get url, (error, response, body) =>
        if error
          if error.code is "ENOTFOUND"
            env.logger.warn "Cannot connect to :" + url
            placeholder = "<div class=\"wunderground\">Server not reachable at the moment.</div>"
            @setWeather(placeholder)
          else
            env.logger.error error

          return

        if typeof body == 'object'
          data = body
        else
          try
            data = JSON.parse(body)
          catch err
            env.logger.warn err
            placeholder = "<div class=\"wunderground\">Error on parsing server response.</div>"
            @setWeather(placeholder)
            return

        if data
          pc = ''
          pc = pc + '<div class="col-1">'
          pc = pc + ' <div class="icon"><i id="icon" class=""></i></div>'
          pc = pc + ' <div class="aktuell">'
          pc = pc + '   <div class="caption">Aktuelles Wetter:</div>'
          pc = pc + '   <div id="weather_str"></div>'
          pc = pc + ' </div>'
          pc = pc + '</div>'
          pc = pc + '<div class="col-2">'
          pc = pc + ' <div class="icon"><i id="icon" class="wi wi-thermometer"></i></div>'
          pc = pc + ' <div class="temp"><div id="temp"></div><div class="unit">&deg;C</div></div>'
          pc = pc + ' <div class="icon"><i id="icon" class="wi wi-humidity"></i></div>'
          pc = pc + ' <div class="hum"><div id="hum"></div></div>'
          pc = pc + '</div>'

          weather_str = data.current_observation.weather
          temp = data.current_observation.temp_c
          hum = data.current_observation.relative_humidity

          icon = @detectIconClass(data.current_observation.icon)

          pc = pc.replace('<i id="icon" class="">', '<i id="icon" class="' + icon + '">')
          pc = pc.replace('<div id="weather_str">', '<div id="weather_str">' + weather_str)
          pc = pc.replace('<div id="temp">', '<div id="temp">' + temp)
          pc = pc.replace('<div id="hum">', '<div id="hum">' + hum)

          # HANDLE FORECAST
          if @days and @days > 1
            fcStr = ''

            url = forecastUrl.replace('{apiKey}', @apiKey).replace('{country}', @country).replace('{city}', @city)
            if @state? and @state.length > 0
              url = url.replace('{state}', @state + '/')
            else
              url = url.replace('{state}', '')

              Request.get url, (error, response, body) =>
                if error
                  if error.code is "ENOTFOUND"
                    env.logger.warn "Cannot connect to :" + url
                    fcStr = "<div class=\"wunderground\">Server not reachable at the moment.</div>"
                  else
                    env.logger.error error

                else
                  if typeof body == 'object'
                    data = body
                  else
                    try
                      data = JSON.parse(body)
                    catch err
                      env.logger.warn err
                      fcStr = "<div class=\"wunderground\">Error on parsing server response.</div>"

                  if data
                    i = 1
                    while i <= @days
                      day = i + 1
                      fcStr = fcStr + '<div class="col-1">' + '<div class="icon"><i id="icon_f_' + i + '" class=""></i></div>'
                      fcStr = fcStr + '<div class="forecast"><div class="caption">Vorschau f&uuml;r Tag ' + day + ':</div><div class="forecast_str_style" id="forecast_str_' + i + '"></div></div>' + '</div>'
                      fcStr = fcStr + '<div class="col-2">' + '<div class="icon"><i class="wi wi-thermometer"></i><i class="wi wi-direction-up"></i></div>' + '<div class="temp_high"><div class="temp-style" id="temp_high_' + i + '"></div><div class="unit">&deg;C</div></div>'
                      fcStr = fcStr + '<div class="icon"><i class="wi wi-thermometer-exterior"></i><i class="wi wi-direction-down"></i></div>' + '<div class="temp_low"><div class="temp-style" id="temp_low_' + i + '"></div><div class="unit">&deg;C</div></div>' + '</div>'
                      i++

                    i = 1
                    while i <= @days
                      forecast_str = data.forecast.txt_forecast.forecastday[i + 1].fcttext_metric
                      temp_high = data.forecast.simpleforecast.forecastday[i].high.celsius
                      temp_low = data.forecast.simpleforecast.forecastday[i].low.celsius
                      icon_f = @detectIconClass(data.forecast.txt_forecast.forecastday[i + 1].icon)


                      fcStr = fcStr.replace('icon_f_'+ i + ' class=""', 'icon_f_'+ i + ' class="' + icon_f + '"')
                      fcStr = fcStr.replace('id="forecast_str_' + i + '">', 'id="forecast_str_' + i + '">' + forecast_str)
                      fcStr = fcStr.replace('id="temp_high_' + i + '">', 'id="temp_high_' + i + '">' + temp_high)
                      fcStr = fcStr.replace('id="temp_low_' + i + '">', 'id="temp_low_' + i + '">' + temp_low)
                      i++

                    pc = pc + fcStr

                    @setWeather(pc)
          else
            @setWeather(pc)


    destroy: ->
      super()


  wundergroundPlugin = new WundergroundPlugin
  return wundergroundPlugin