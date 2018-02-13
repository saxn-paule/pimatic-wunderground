Get your free developer key here: https://www.wunderground.com/weather/api/d/pricing.html

Choose your preferred language from here: https://www.wunderground.com/weather/api/d/docs?d=language-support

Find your Location here: https://www.wunderground.com/

As long there is no solution for using custom fonts in plugins, please copy the fonts folder to mobile-frontend folder
```
 cp -R /home/pi/pimatic-app/node_modules/pimatic-wunderground/app/fonts/ /home/pi/pimatic-app/node_modules/pimatic-mobile-frontend/public/

```

The WundergroundDevice provides five variables
* **currentTemp:** the current temperature in °C
* **currentWind:** the current wind speed in km/h
* **currentWindString:** the current wind description
* **currentWeather:** the current weather description
* **currentGust:** the current gust speed in km/h


# Beware
This plugin is in an early alpha stadium and you use it on your own risk.
I'm not responsible for any possible damages that occur on your health, hard- or software.

# License
MIT
