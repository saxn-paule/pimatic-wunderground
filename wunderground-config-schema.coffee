# #wunderground configuration options
# Declare your config option for your plugin here. 
module.exports = {
	title: "wunderground config options"
	type: "object"
	properties:
		apiKey:
			description: "The apiKey"
			type: "string"
			default: ""
		days:
			description: "For how many days should the forecast be shown"
			type: "string"
			default: ""
		country:
			description: "The country"
			type: "string"
			default: ""
		state:
			description: "The state"
			type: "string"
			default: ""
		city:
			description: "The city"
			type: "string"
			default: ""
}