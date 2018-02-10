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
          mobileFrontend.registerAssetFile 'css', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.eot"
          mobileFrontend.registerAssetFile 'css', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.svg"
          mobileFrontend.registerAssetFile 'css', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.ttf"
          mobileFrontend.registerAssetFile 'css', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.woff"
          mobileFrontend.registerAssetFile 'css', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.woff2"

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

    reloadWeather: ->

      url = forecastUrl.replace('{apiKey}', @apiKey).replace('{country}', @country).replace('{city}', @city)
      if @state? and @state.length > 0
        url = url.replace('{state}', @state + '/')
      else
        url = url.replace('{state}', '')


      Request.get url, (error, response, body) =>
        env.logger.info "requesting url :" + url
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
            #data = mockJson
          catch err
            env.logger.warn err
            placeholder = "<div class=\"wunderground\">Error on parsing server response.</div>"
            @setWeather(placeholder)
            return

        env.logger.info "data :" + data

        if data
          pc = ''
          i = 1
          while i <= @days
            day = i + 1
            pc = pc + '<div class="col-1">' + '<div class="icon"><i id="icon_f_' + i + '" class=""></i></div>'
            pc = pc + '<div class="forecast"><div class="caption">Vorschau f&uuml;r Tag ' + day + ':</div><div class="forecast_str_style" id="forecast_str_' + i + '"></div></div>' + '</div>'
            pc = pc + '<div class="col-2">' + '<div class="icon"><i class="wi wi-thermometer"></i><i class="wi wi-direction-up"></i></div>' + '<div class="temp_high"><div class="temp-style" id="temp_high_' + i + '"></div><div class="unit">&deg;C</div></div>'
            pc = pc + '<div class="icon"><i class="wi wi-thermometer-exterior"></i><i class="wi wi-direction-down"></i></div>' + '<div class="temp_low"><div class="temp-style" id="temp_low_' + i + '"></div><div class="unit">&deg;C</div></div>' + '</div>'

            i++

          i = 1
          while i <= @days
            forecast_str = data.forecast.txt_forecast.forecastday[i + 1].fcttext_metric
            temp_high = data.forecast.simpleforecast.forecastday[i].high.celsius
            temp_low = data.forecast.simpleforecast.forecastday[i].low.celsius
            icon_f = undefined
            icons_f = data.forecast.txt_forecast.forecastday[i + 1].icon
            switch icons_f
              when 'clear'
                icon_f = 'wi wi-day-sunny'
              when 'cloudy'
                icon_f = 'wi wi-day-cloudy'
              when 'flurries'
                icon_f = 'wi wi-day-sleet'
              when 'fog'
                icon_f = 'wi wi-day-fog'
              when 'hazy'
                icon_f = 'wi wi-day-haze'
              when 'mostlycloudy'
                icon_f = 'wi wi-day-cloudy'
              when 'mostlysunny'
                icon_f = 'wi wi-day-sunny-overcast'
              when 'sleet'
                icon_f = 'wi wi-day-sleet'
              when 'rain'
                icon_f = 'wi wi-day-showers'
              when 'snow'
                icon_f = 'wi wi-day-snow'
              when 'sunny'
                icon_f = 'wi wi-day-sunny'
              when 'tstorms'
                icon_f = 'wi wi-day-thunderstorm'
              when 'unknown'
                icon_f = 'wi wi-day-thunderstorm'
              when 'partlycloudy'
                icon_f = 'wi wi-day-cloudy'
              when 'nt_clear'
                icon_f = 'wi wi-stars'
              when 'nt_cloudy'
                icon_f = 'wi wi-night-alt-cloudy'
              when 'nt_flurries'
                icon_f = 'wi wi-night-alt-sleet'
              when 'nt_fog'
                icon_f = 'wi wi-night-fog'
              when 'nt_hazy'
                icon_f = 'wi wi-night-haze'
              when 'nt_mostlycloudy'
                icon_f = 'wi wi-night-cloudy'
              when 'nt_mostlysunny'
                icon_f = 'wi wi-night-sunny-overcast'
              when 'nt_sleet'
                icon_f = 'wi wi-night-sleet'
              when 'nt_rain'
                icon_f = 'wi wi-night-showers'
              when 'nt_snow'
                icon_f = 'wi wi-night-snow'
              when 'nt_sunny'
                icon_f = 'wi wi-night-sunny'
              when 'nt_tstorms'
                icon_f = 'wi wi-night-thunderstorm'
              when 'nt_unknown'
                icon_f = 'wi wi-night-thunderstorm'
              when 'nt_partlycloudy'
                icon_f = 'wi wi-night-cloudy'

            pc = pc.replace('icon_f_'+ i + ' class=""', 'icon_f_'+ i + ' class="' + icon_f + '"')
            pc = pc.replace('id="forecast_str_' + i + '">', 'id="forecast_str_' + i + '">' + forecast_str)
            pc = pc.replace('id="temp_high_' + i + '">', 'id="temp_high_' + i + '">' + temp_high)
            pc = pc.replace('id="temp_low_' + i + '">', 'id="temp_low_' + i + '">' + temp_low)

            i++

          @setWeather(pc)

      #End Request part

    destroy: ->
      super()


  wundergroundPlugin = new WundergroundPlugin
  return wundergroundPlugin