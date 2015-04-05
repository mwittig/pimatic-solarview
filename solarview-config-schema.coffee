# #pimatic-solarview configuration options
module.exports = {
  title: "SolarView plugin config options"
  type: "object"
  properties:
    host:
      description: "SolarView Server Address"
      type: "string"
      default: "fritz.box"
    port:
      description: "SolarView Server TCP Port"
      type: "number"
      default: 15000
    interval:
      description: "Polling interval for data requests"
      type: "number"
      default: 10
}