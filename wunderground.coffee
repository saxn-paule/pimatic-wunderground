module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  M = env.matcher
  t = env.require('decl-api').types
  Request = require 'request'
  actualUrl = "http://api.wunderground.com/api/{apiKey}/conditions/lang:{lang}/q/{country}/{state}{city}.json";
  historyUrl = "http://api.wunderground.com/api/{apiKey}/history_{historyDate}/lang:{lang}/q/{country}/{state}{city}.json";
  actualPwsUrl = "http://api.wunderground.com/api/{apiKey}/conditions/lang:{lang}/q/pws:{pws}.json";
  forecastUrl = "http://api.wunderground.com/api/{apiKey}/forecast/lang:{lang}/q/{country}/{state}{city}.json";
  forecastPwsUrl = "http://api.wunderground.com/api/{apiKey}/forecast/lang:{lang}/q/pws:{pws}.json";

  class WundergroundPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass("WundergroundDevice",{
        configDef : deviceConfigDef.WundergroundDevice,
        createCallback : (config) => new WundergroundDevice(config,this)
      })

      @framework.deviceManager.registerDeviceClass("WundergroundHistoryDevice",{
        configDef : deviceConfigDef.WundergroundHistoryDevice,
        createCallback : (config) => new WundergroundHistoryDevice(config,this)
      })

      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-wunderground/app/wundergroundTempl-page.coffee"
          mobileFrontend.registerAssetFile 'html', "pimatic-wunderground/app/wundergroundTempl-template.html"
          mobileFrontend.registerAssetFile 'css', "pimatic-wunderground/app/css/wunderground.css"
          mobileFrontend.registerAssetFile 'css', "pimatic-wunderground/app/css/weather-icons.css"
          ###
          mobileFrontend.registerAssetFile 'eot', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.eot"
          mobileFrontend.registerAssetFile 'svg', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.svg"
          mobileFrontend.registerAssetFile 'ttf', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.ttf"
          mobileFrontend.registerAssetFile 'woff', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.woff"
          mobileFrontend.registerAssetFile 'woff2', "pimatic-wunderground/app/fonts/weathericons-regular-webfont.woff2"
          ###
        return

  class WundergroundDevice extends env.devices.Device
    template: 'wunderground'

    attributes:
      weather:
        description: 'the weather data'
        type: t.string
      currentTemp:
        description: 'the current temperature in °C'
        type: t.number
      currentWind:
        description: 'the current wind speed in km/h'
        type: t.number
      currentWindDir:
        description: 'the current wind speed in km/h'
        type: t.string
      currentWindString:
        description: 'the current wind description'
        type: t.string
      currentWeather:
        description: 'the current weather description'
        type: t.string
      currentGust:
        description: 'the current gust speed in km/h'
        type: t.number


    constructor: (@config, @plugin) ->
      @id = @config.id
      @name = @config.name
      @apiKey = @config.apiKey
      @country = @config.country
      @state = @config.state
      @city = @config.city
      @days = @config.days
      @pws = @config.pws
      @lang = @config.lang or 'DL'
      @interval = @config.interval or 30
      @weather = ''

      @currentTemp = lastState?["currentTemp"]?.value
      @currentWind = lastState?["currentWind"]?.value
      @currentWindString = lastState?["currentWindString"]?.value
      @currentWindDir = lastState?["currentWindDir"]?.value
      @currentWeather = lastState?["currentWeather"]?.value
      @currentGust = lastState?["currentGust"]?.value

      @reloadWeather()

      @timerId = setInterval ( =>
        @reloadWeather()
      ), (@interval * 1000 * 60)

      updateValue = =>
        if @config.interval > 0
          @_updateValueTimeout = null
          @_getUpdatedCurrentTemp().finally( =>
            @_getUpdatedCurrentWind().finally( =>
              @_getUpdatedCurrentWindDir().finally( =>
                @_getUpdatedCurrentWindString().finally( =>
                  @_getUpdatedCurrentWeather().finally( =>
                    @_getUpdatedCurrentGust().finally( =>
                      @_updateValueTimeout = setTimeout(updateValue, 300000)
                    )
                  )
                )
              )
            )
          )


      super()
      updateValue()

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

    getPws: -> Promise.resolve(@pws)

    setPws: (value) ->
      if @pws is value then return
      @pws = value

    getWeather: -> Promise.resolve(@weather)

    setWeather: (value) ->
      @weather = value
      @emit 'weather', value

    getCurrentTemp: -> Promise.resolve(@currentTemp)

    setCurrentTemp: (value) ->
      @currentTemp = value
      @emit 'currentTemp', value

    getCurrentWind: -> Promise.resolve(@currentWind)

    setCurrentWind: (value) ->
      @currentWind = value
      @emit 'currentWind', value

    getCurrentWindDir: -> Promise.resolve(@currentWindDir)

    setCurrentWindDir: (value) ->
      @currentWindDir = value
      @emit 'currentWindDir', value

    getCurrentWindString: -> Promise.resolve(@currentWindString)

    setCurrentWindString: (value) ->
      @currentWindString = value
      @emit 'currentWindString', value

    getCurrentWeather: -> Promise.resolve(@currentWeather)

    setCurrentWeather: (value) ->
      @currentWeather = value
      @emit 'currentWeather', value

    getCurrentGust: -> Promise.resolve(@currentGust)

    setCurrentGust: (value) ->
      @currentGust = value
      @emit 'currentGust', value

    _getUpdatedCurrentTemp: () =>
      @emit "currentTemp", @currentTemp
      return Promise.resolve @currentTemp

    _getUpdatedCurrentWind: () =>
      @emit "currentWind", @currentWind
      return Promise.resolve @currentWind

    _getUpdatedCurrentWindDir: () =>
      @emit "currentWindDir", @currentWindDir
      return Promise.resolve @currentWindDir

    _getUpdatedCurrentWindString: () =>
      @emit "currentWindString", @currentWindString
      return Promise.resolve @currentWindString

    _getUpdatedCurrentWeather: () =>
      @emit "currentWeather", @currentWeather
      return Promise.resolve @currentWeather

    _getUpdatedCurrentGust: () =>
      @emit "currentGust", @currentGust
      return Promise.resolve @currentGust


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
      env.logger.info "Reloading weather data..."
      if @pws? and @pws.length > 0
        url = actualPwsUrl.replace('{apiKey}', @apiKey).replace('{pws}', @pws).replace('{lang}', @lang)
      else
        url = actualUrl.replace('{apiKey}', @apiKey).replace('{country}', @country).replace('{city}', @city).replace('{lang}', @lang)

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

        if data and data.current_observation
          pc = ''
          pc = pc + '<div class="col-1">'
          pc = pc + ' <div class="icon"><i id="icon" class=""></i></div>'
          pc = pc + ' <div class="aktuell">'
          pc = pc + '   <div class="caption"></div>'
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
          location = data.current_observation.display_location.full

          icon = @detectIconClass(data.current_observation.icon)

          pc = pc.replace('<i id="icon" class="">', '<i id="icon" class="' + icon + '">')
          pc = pc.replace('<div class="caption">', '<div class="caption">' + location)
          pc = pc.replace('<div id="weather_str">', '<div id="weather_str">' + weather_str)
          pc = pc.replace('<div id="temp">', '<div id="temp">' + temp)
          pc = pc.replace('<div id="hum">', '<div id="hum">' + hum)

          # FILL ATTRIBUTES
          @setCurrentTemp(parseFloat(data.current_observation.temp_c))
          @setCurrentGust(parseFloat(data.current_observation.wind_gust_kph))
          @setCurrentWeather(data.current_observation.weather)
          @setCurrentWind(parseFloat(data.current_observation.wind_kph))
          @setCurrentWindString(data.current_observation.wind_string)
          @setCurrentWindDir(data.current_observation.wind_dir)

          # HANDLE FORECAST
          if @days and @days > 0
            fcStr = ''

            if @pws? and @pws.length > 0
              url = forecastPwsUrl.replace('{apiKey}', @apiKey).replace('{pws}', @pws).replace('{lang}', @lang)
            else
              url = forecastUrl.replace('{apiKey}', @apiKey).replace('{country}', @country).replace('{city}', @city).replace('{lang}', @lang)
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

                if data and data.forecast and data.forecast.simpleforecast
                  i = 1
                  while i <= @days
                    if data.forecast.simpleforecast.forecastday[i]
                      day = i + 1
                      fcStr = fcStr + '<div class="col-1">' + '<div class="icon"><i id="icon_f_' + i + '" class=""></i></div>'
                      fcStr = fcStr + '<div class="forecast"><div class="caption' + i + '"></div><div class="forecast_str_style" id="forecast_str_' + i + '"></div></div>' + '</div>'
                      fcStr = fcStr + '<div class="col-2">' + '<div class="icon"><i class="wi wi-thermometer"></i><i class="wi wi-direction-up"></i></div>' + '<div class="temp_high"><div class="temp-style" id="temp_high_' + i + '"></div><div class="unit">&deg;C</div></div>'
                      fcStr = fcStr + '<div class="icon"><i class="wi wi-thermometer-exterior"></i><i class="wi wi-direction-down"></i></div>' + '<div class="temp_low"><div class="temp-style" id="temp_low_' + i + '"></div><div class="unit">&deg;C</div></div>' + '</div>'

                    i++

                  i = 1
                  while i <= @days
                    if data.forecast.simpleforecast.forecastday[i]
                      weekday = data.forecast.simpleforecast.forecastday[i].date.weekday
                      forecast_str = data.forecast.txt_forecast.forecastday[i + 1].fcttext_metric
                      temp_high = data.forecast.simpleforecast.forecastday[i].high.celsius
                      temp_low = data.forecast.simpleforecast.forecastday[i].low.celsius
                      icon_f = @detectIconClass(data.forecast.txt_forecast.forecastday[i + 1].icon)

                      fcStr = fcStr.replace('icon_f_'+ i + ' class=""', 'icon_f_'+ i + ' class="' + icon_f + '"')
                      fcStr = fcStr.replace('id="forecast_str_' + i + '">', 'id="forecast_str_' + i + '">' + forecast_str)
                      fcStr = fcStr.replace('id="temp_high_' + i + '">', 'id="temp_high_' + i + '">' + temp_high)
                      fcStr = fcStr.replace('id="temp_low_' + i + '">', 'id="temp_low_' + i + '">' + temp_low)
                      fcStr = fcStr.replace('<div class="caption' + i + '">', '<div class="caption">' + weekday)
                    else
                      env.logger.warn 'no forecast for day ' + i + ' available'

                    i++

                  pc = pc + fcStr

                  @setWeather(pc)

                else
                  @setWeather(pc)

                  if @days > 0
                    env.logger.warn "no forecast available"

          else
            @setWeather(pc)

        else
          if data and data.response and data.response.error
            @setWeather("<div class=\"wunderground\">" + data.response.error.description + "</div>")
          else
            @setWeather("<div class=\"wunderground\">Error on parsing server response.</div>")


    destroy: ->
      super()

  class WundergroundHistoryDevice extends env.devices.Device
    template: 'wunderground'

    attributes:
      rain:
        description: 'rain in mm'
        type: t.string
      temperature:
        description: 'the past temperature in °C'
        type: t.number
      humidity:
        description: 'the past humidity in %'
        type: t.number

    constructor: (@config, @plugin) ->
      @id = @config.id
      @name = @config.name
      @apiKey = @config.apiKey
      @country = @config.country
      @state = @config.state
      @city = @config.city
      @dayOffset = @config.dayOffset
      @timeOffset = @config.timeOffset
      @lang = @config.lang or 'DL'
      @interval = @config.interval or 30

      @rain = lastState?["rain"]?.value
      @temperature = lastState?["temperature"]?.value
      @humidity = lastState?["humidity"]?.value

      @reloadHistoryWeather()

      @timerId = setInterval ( =>
        @reloadHistoryWeather()
      ), (@interval * 1000 * 60)

      updateValues = =>
        if @config.interval > 0
          @_updateValueTimeout = null
          @_getUpdatedPastTemperature().finally( =>
            @_getUpdatedPastHumidity().finally( =>
              @_getUpdatedPastRain().finally( =>
                @_updateValueTimeout = setTimeout(updateValues, 300000)
              )
            )
          )


      super()
      updateValues()

    destroy: () ->
      if @timerId?
        clearInterval @timerId
        @timerId = null
      super()

    getApiKey: -> Promise.resolve(@apiKey)

    setApiKey: (value) ->
      if @apiKey is value then return
      @apiKey = value

    getDayOffset: -> Promise.resolve(@dayOffset)

    setDayOffset: (value) ->
      if @days is value then return
      @dayOffset = value

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

    getTemperature: -> Promise.resolve(@temperature)

    setTemperature: (value) ->
      @temperature = value
      @emit 'temperature', value

    getHumidity: -> Promise.resolve(@humidity)

    setHumidity: (value) ->
      @humidity = value
      @emit 'humidity', value

    getRain: -> Promise.resolve(@rain)

    setRain: (value) ->
      @rain = value
      @emit 'rain', value

    _getUpdatedPastTemperature: () =>
      @emit "temperature", @temperature
      return Promise.resolve @temperature

    _getUpdatedPastHumidity: () =>
      @emit "humidity", @humidity
      return Promise.resolve @humidity

    _getUpdatedPastRain: () =>
      @emit "rain", @rain
      return Promise.resolve @rain

    reloadHistoryWeather: ->
      env.logger.info "Reloading history weather data..."

      url = historyUrl.replace('{apiKey}', @apiKey).replace('{country}', @country).replace('{city}', @city).replace('{lang}', @lang)

      if @state? and @state.length > 0
        url = url.replace('{state}', @state + '/')
      else
        url = url.replace('{state}', '')

      # date date to request
      now = new Date().getTime()

      if @timeOffset < 0
        offsetHours = @timeOffset * 60 * 60 * 1000
      else
        offsetHours = 0

      if @dayOffset < 0
        offsetDays = @dayOffset * 24 * 60 * 60 * 1000
      else
        offsetDays = 0

      past = new Date(now + offsetDays + offsetHours)

      env.logger.info "Past: " + past

      pastYear = past.getUTCFullYear()

      pastMonth = past.getUTCMonth() + 1
      if pastMonth.length < 2
        pastMonth = "0" + pastMonth;

      pastDay = past.getUTCDate()
      if pastDay.length < 2
        pastDay = "0" + pastDay;

      url = url.replace('{historyDate}', "" + pastYear + pastMonth + pastDay)

      env.logger.info "Requesting url: " + url

      Request.get url, (error, response, body) =>
        if error
          if error.code is "ENOTFOUND"
            env.logger.warn "Cannot connect to :" + url
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
            return

        if data and data.history.observations
          observations = data.history.observations

          pastYear = past.getUTCFullYear()
          pastMonth = past.getUTCMonth() + 1
          pastDay = past.getUTCDate()
          pastHour = past.getUTCHours()

          i = 0
          match = 0
          diffYear = 100
          diffMonth = 100
          diffDay = 100
          diffHour = 100

          # Find the matching entry by smallest difference to given date
          while i < observations.length
            observationEntry = observations[i]

            env.logger.info JSON.stringify(observationEntry)

            obDate = observationEntry.utcdate

            tempYear = Math.abs(obDate.year - pastYear)
            tempMonth = Math.abs(obDate.mon - pastMonth)
            tempDay = Math.abs(obDate.mday - pastDay)
            tempHour = Math.abs(obDate.hour - pastHour)

            if tempYear < diffYear
              diffYear = tempYear
              if tempMonth < diffMonth
                diffMonth = tempMonth
                if tempDay < diffDay
                  diffDay = tempDay
                  if tempHour < diffHour
                    diffHour = tempHour
                    match = i

            i++

          # FILL ATTRIBUTES
          @setTemperature(parseFloat(observations[match].tempm))
          @setHumidity(parseFloat(observations[match].hum))
          @setRain(parseInt(observations[match].rain))

        else
          if data and data.response and data.response.error
            env.logger.warn data.response.error.description
          else
            env.logger.warn "Error on parsing server response."


    destroy: ->
      super()

  wundergroundPlugin = new WundergroundPlugin
  return wundergroundPlugin