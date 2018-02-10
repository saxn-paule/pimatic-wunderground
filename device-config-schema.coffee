module.exports = {
	title: "wunderground"
	WundergroundDevice :{
		title: "Plugin Properties"
		type: "object"
		extensions: ["xLink"]
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
}