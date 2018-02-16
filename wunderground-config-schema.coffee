# #wunderground configuration options
# Declare your config option for your plugin here. 
module.exports = {
	title: "wunderground config options"
	type: "object"
	properties:
		debug:
			description: "Enabled debug messages"
			type: "boolean"
			default: false
}