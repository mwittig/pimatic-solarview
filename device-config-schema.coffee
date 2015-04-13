module.exports = {
  title: "pimatic-solarview device config schemas"
  SolarViewInverterSimple: {
    title: "SolarView Inverter Simplified View"
    description: "Provides energy earnings and current power values. Use this for the sum if you more than one inverter"
    type: "object"
    properties:
      inverterId:
        description: "Inverter Id [0 - 9], use 0 for the sum of all inverters"
        type: "number"
        default: 0
  }
  SolarViewInverter: {
    title: "SolarView Inverter"
    description: "Additionally provides grid voltage, grid amperage, and inverter temperature values"
    type: "object"
    properties:
      inverterId:
        description: "Inverter Id [1 - 9]"
        type: "number"
        default: 1
  }
  SolarViewInverterWithMPPTracker: {
    title: "SolarView Inverter with MPP Tracker"
    description: "Additionally provides string voltage and amperage for three MPP trackers"
    type: "object"
    properties:
      inverterId:
        description: "Inverter Id [1 - 9]"
        type: "number"
        default: 1
  }
}