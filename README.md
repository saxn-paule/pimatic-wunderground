Get your free developer key here: https://www.wunderground.com/weather/api/d/pricing.html

Choose your preferred language from here: https://www.wunderground.com/weather/api/d/docs?d=language-support

Find your Location here: https://www.wunderground.com/

As long there is no solution for using custom fonts in plugins, please copy the fonts folder to mobile-frontend folder
```
 cp -R /home/pi/pimatic-app/node_modules/pimatic-wunderground/app/fonts/ /home/pi/pimatic-app/node_modules/pimatic-mobile-frontend/public/

```

The WundergroundDevice provides the following variables
* **currentTemp:** the current temperature in °C
* **currentHumidity:** the current humidity in %
* **currentWind:** the current wind speed in km/h
* **currentWindString:** the current wind description
* **currentWindDir:** the current wind speed in km/h
* **currentWeather:** the current weather description
* **currentGust:** the current gust speed in km/h
* **dewPoint:** the current dewpoint in °C
* **heatIndex:** the current heatindex in °C
* **solarradiation:** the current solarradiation
* **uv:** the current UV index
        

The WundergroundHistoryDevice provides the following variables
* **rain:** rain in mm
* **temperature:** the past temperature in °C
* **humidity:** the past humidity in %
* **precip:** the hourly past precipitation in mm
* **precip_total:** the total past precipitation for the current day in mm
* **solarradiation:** the current solarradiation
* **uv:** the current UV index

# Beware
This plugin is in an early alpha stadium and you use it on your own risk.
I'm not responsible for any possible damages that occur on your health, hard- or software.

# License
MIT
