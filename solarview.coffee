# #SolarView plugin

module.exports = (env) ->

  # Require the bluebird promise library
  Promise = env.require 'bluebird'

  # Require the nodejs net API
  net = require 'net'

  # ###SolarViewPlugin class
  class SolarViewPlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      # register devices
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("SolarViewInverterSimple", {
        configDef: deviceConfigDef.SolarViewInverterSimple,
        createCallback: (config) =>
          return new SolarViewInverterSimpleDevice(config, this)
      })

      @framework.deviceManager.registerDeviceClass("SolarViewInverter", {
        configDef: deviceConfigDef.SolarViewInverter,
        createCallback: (config) =>
          return new SolarViewInverterDevice(config, this)
      })

      @framework.deviceManager.registerDeviceClass("SolarViewInverterWithMPPTracker", {
        configDef: deviceConfigDef.SolarViewInverterWithMPPTracker,
        createCallback: (config) =>
          return new SolarViewInverterWithMPPTrackerDevice(config, this)
      })


  class SolarViewInverterBaseDevice extends env.devices.Device
    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin) ->
      env.logger.debug("SolarViewInverterBaseDevice Initialization")
      @host = plugin.config.host
      @port = plugin.config.port
      @id = config.id
      @name = config.name
      @interval = 1000 * (config.interval or plugin.config.interval)
      @inverterId = config.inverterId
      super()

      # keep updating
      @requestUpdate()
      setInterval(=>
        @requestUpdate()
      , @interval
      )


    fetchData: (host, port, inverterId) ->
      socket = net.createConnection port, host
      socket.setNoDelay true

      socket.on 'connect', () ->
        env.logger.debug("Opened connection to #{host}:#{port}.")
        socket.write "0" + inverterId + "*\r\n"

      socket.on 'data', ((data) ->
        env.logger.debug("Received raw data: #{data}")

        rawData = data.toString 'utf8'
        values = rawData.split ","

        if values.length >= 20
          @emit "solarViewData", values

        socket.end()
      ).bind(@)

      socket.on 'error', (error) ->
        if error.code == 'ETIMEDOUT'
          env.logger.error("Timeout fetching SolarView data")
        else
          env.logger.error("Error fetching SolarView data: " + error.toString())


    # poll device according to interval
    requestUpdate: ->
      @fetchData(@host, @port, @inverterId)


  class SolarViewInverterSimpleDevice extends SolarViewInverterBaseDevice
    # attributes
    attributes:
      energyToday:
        description: "Energy Yield Today"
        type: "number"
        unit: 'kWh'
        acronym: 'KDY'
      energyMonth:
        description: "Energy Yield of Current Month"
        type: "number"
        unit: 'kWh'
        acronym: 'KMT'
      energyYear:
        description: "Energy Yield if Current Year"
        type: "number"
        unit: 'kWh'
        acronym: 'KYR'
      energyTotal:
        description: "Energy Yield Total"
        type: "number"
        unit: 'kWh'
        acronym: 'KT0'
      currentPower:
        description: "AC Power"
        type: "number"
        unit: 'W'
        acronym: 'PAC'

    energyToday: 0.0
    energyMonth: 0.0
    energyYear: 0.0
    energyTotal: 0.0
    currentPower: 0.0

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin) ->
      env.logger.debug("SolarViewInverterSimpleDevice Initialization")

      @on 'solarViewData', ((values) ->
        @emit "energyToday", Number values[6]
        @emit "energyMonth", Number values[7]
        @emit "energyYear", Number values[8]
        @emit "energyTotal", Number values[9]
        @emit "currentPower", Number values[10]
      )
      super(@config, @plugin)

    getEnergyToday: -> Promise.resolve @energyToday
    getEnergyMonth: -> Promise.resolve @energyMonth
    getEnergyYear: -> Promise.resolve @energyYear
    getEnergyTotal: -> Promise.resolve @energyTotal
    getCurrentPower: -> Promise.resolve @currentPower


  class SolarViewInverterDevice extends SolarViewInverterSimpleDevice
    # attributes
    attributes:
      energyToday:
        description: "Energy Yield Today"
        type: "number"
        unit: 'kWh'
        acronym: 'KDY'
      energyMonth:
        description: "Energy Yield of Current Month"
        type: "number"
        unit: 'kWh'
        acronym: 'KMT'
      energyYear:
        description: "Energy Yield if Current Year"
        type: "number"
        unit: 'kWh'
        acronym: 'KYR'
      energyTotal:
        description: "Energy Yield Total"
        type: "number"
        unit: 'kWh'
        acronym: 'KT0'
      currentPower:
        description: "AC Power"
        type: "number"
        unit: 'W'
        acronym: 'PAC'
      gridVoltage:
        description: "Grid Voltage"
        type: "number"
        unit: 'V'
        acronym: 'UL1'
      gridAmperage:
        description: "Grid Amperage"
        type: "number"
        unit: 'A'
        acronym: 'IL2'
      inverterTemperature:
        description: "Inverter Temperature"
        type: "number"
        unit: '°C'
        acronym: 'TKK'

    gridVoltage: 0.0
    gridAmperage: 0.0
    inverterTemperature: 0.0

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin) ->
      env.logger.debug("SolarViewInverterDevice Initialization")

      @on 'solarViewData', ((values) ->
        @emit "gridVoltage", Number values[17]
        @emit "gridAmperage", Number values[18]
        @emit "inverterTemperature", Number values[19].replace /\}+$/g, ""
      )
      super(@config, @plugin)

    getGridVoltage: -> Promise.resolve @gridVoltage
    getGridAmperage: -> Promise.resolve @gridAmperage
    getInverterTemperature: -> Promise.resolve @inverterTemperature


  class SolarViewInverterWithMPPTrackerDevice extends SolarViewInverterDevice
    # base class attributes
    attributes:
      energyToday:
        description: "Energy Yield Today"
        type: "number"
        unit: 'kWh'
        acronym: 'KDY'
      energyMonth:
        description: "Energy Yield of Current Month"
        type: "number"
        unit: 'kWh'
        acronym: 'KMT'
      energyYear:
        description: "Energy Yield if Current Year"
        type: "number"
        unit: 'kWh'
        acronym: 'KYR'
      energyTotal:
        description: "Energy Yield Total"
        type: "number"
        unit: 'kWh'
        acronym: 'KT0'
      currentPower:
        description: "AC Power"
        type: "number"
        unit: 'W'
        acronym: 'PAC'
      gridVoltage:
        description: "Grid Voltage"
        type: "number"
        unit: 'V'
        acronym: 'UL1'
      gridAmperage:
        description: "Grid Amperage"
        type: "number"
        unit: 'A'
        acronym: 'IL2'
    # derived class attributes
      inverterTemperature:
        description: "Inverter Temperature"
        type: "number"
        unit: '°C'
        acronym: 'TKK'
      dcVoltageStringA:
        description: "DC Voltage of String A"
        type: "number"
        unit: 'V'
        acronym: 'UDC'
      dcVoltageStringB:
        description: "DC Voltage of String B"
        type: "number"
        unit: 'V'
        acronym: 'UDCB'
      dcVoltageStringC:
        description: "DC Voltage of String C"
        type: "number"
        unit: 'V'
        acronym: 'UDCC'
      dcAmperageStringA:
        description: "DC Power of String A"
        type: "number"
        unit: 'A'
        acronym: 'IDC'
      dcAmperageStringB:
        description: "DC Power of String B"
        type: "number"
        unit: 'A'
        acronym: 'IDCB'
      dcAmperageStringC:
        description: "DC Power of String C"
        type: "number"
        unit: 'A',
        acronym: 'IDCC'

    dcVoltageStringA: 0.0
    dcVoltageStringB: 0.0
    dcVoltageStringC: 0.0
    dcAmperageStringA: 0.0
    dcAmperageStringB: 0.0
    dcAmperageStringC: 0.0

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin) ->
      env.logger.debug("SolarViewInverterWithMPPTrackerDevice Initialization")

      @on 'solarViewData', ((values) ->
        @emit "dcVoltageStringA", Number values[11]
        @emit "dcAmperageStringA", Number values[12]
        @emit "dcVoltageStringB", Number values[13]
        @emit "dcAmperageStringB", Number values[14]
        @emit "dcVoltageStringC", Number values[15]
        @emit "dcAmperageStringC", Number values[16]
      )
      super(@config, @plugin)

    getDcVoltageStringA: -> Promise.resolve @dcVoltageStringA
    getDcVoltageStringB: -> Promise.resolve @dcVoltageStringB
    getDcVoltageStringC: -> Promise.resolve @dcVoltageStringC
    getDcAmperageStringA: -> Promise.resolve @dcAmperageStringA
    getDcAmperageStringB: -> Promise.resolve @dcAmperageStringB
    getDcAmperageStringC: -> Promise.resolve @dcAmperageStringC


  # ###Finally
  # Create a instance of my plugin
  myPlugin = new SolarViewPlugin
  # and return it to the framework.
  return myPlugin