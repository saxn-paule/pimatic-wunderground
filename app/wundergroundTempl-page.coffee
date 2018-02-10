$(document).on( "templateinit", (event) ->
# define the item class
	class wundergroundDeviceItem extends pimatic.DeviceItem
		constructor: (templData, @device) ->
			@id = @device.id
			super(templData,@device)

		afterRender: (elements) ->
			super(elements)

			renderWeather = (newval) =>
				$("#"+@id+"_wunderground_placeholder").html(newval)

			renderWeather(@getAttribute('weather').value())

			@getAttribute('weather').value.subscribe(renderWeather)

			return
			
	# register the item-class
	pimatic.templateClasses['wunderground'] = wundergroundDeviceItem
)