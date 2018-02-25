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
				required: true
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
			pws:
				description: "ID of private weather station"
				type: "string"
				default: ""
			lang:
				description: "The language"
				type: "string"
				default: "DL"
			interval:
				description: "Update interval in minutes"
				type: "number"
				default: 30
	}
}
