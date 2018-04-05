module.exports = {
	title: "wunderground"
	WundergroundDevice :{
		title: "WundergroundDevice Properties"
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
	WundergroundHistoryDevice :{
		title: "WundergroundHistoryDevice Properties"
		type: "object"
		extensions: ["xLink", "xAttributeOptions"]
		properties:
			apiKey:
				description: "The apiKey"
				type: "string"
				default: ""
				required: true
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
			lang:
				description: "The language"
				type: "string"
				default: "DL"
			interval:
				description: "Update interval in minutes"
				type: "number"
				default: 30
			dayOffset:
				description: "how many days in the past"
				type: "number"
				default: 0
			timeOffset:
				description: "How many hours in the past."
				type: "number"
				default: -7
			attributes:
				description: "Attributes which shall be exposed by the device"
				type: "array"
				default: []
				format: "table"
				items:
					type: "object"
					properties:
						name:
							enum: [
								"rain", "temperature", "humidity"
							]
							description: "weather related attributes"
						label:
							type: "string"
							description: "The attribute label text to be displayed. The name will be displayed if not set"
							required: false
						unit:
							description: "The unit of the variable. Only works if type is a number."
							type: "string"
							required: false
	}
}