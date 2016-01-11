# #SolarView plugin

module.exports = (env) ->

  # Require the bluebird promise library
  Promise = env.require 'bluebird'

  # Require the nodejs net API
  net = require 'net'

  # Require pimatic-plugin-commons for common helper functions
  commons = require('pimatic-plugin-commons')(env)

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
        createCallback: (config, lastState) =>
          return new SolarViewInverterSimpleDevice(config, this, lastState)
      })

      @framework.deviceManager.registerDeviceClass("SolarViewInverter", {
        configDef: deviceConfigDef.SolarViewInverter,
        createCallback: (config, lastState) =>
          return new SolarViewInverterDevice(config, this, lastState)
      })

      @framework.deviceManager.registerDeviceClass("SolarViewInverterWithMPPTracker", {
        configDef: deviceConfigDef.SolarViewInverterWithMPPTracker,
        createCallback: (config, lastState) =>
          return new SolarViewInverterWithMPPTrackerDevice(config, this, lastState)
      })


  class SolarViewInverterBaseDevice extends env.devices.Device
    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      @debug = @plugin.config.debug || false
      @_base = commons.base @, config.class      
      @_base.debug("SolarViewInverterBaseDevice Initialization")
      @host = plugin.config.host
      @port = plugin.config.port
      @id = config.id
      @name = config.name
      @interval = @_base.normalize 10000, 1000 * (config.interval or plugin.config.interval or 10)
      @timeout = Math.min @interval, 20000
      @inverterId = config.inverterId
      super()
      process.nextTick () =>
        @requestUpdate()


    fetchData: (host, port, inverterId) ->
      return new Promise (resolve, reject) =>
        @_base.debug "Trying to connect to #{@host}:#{@port}"
        socket = net.createConnection port, host
        socket.setNoDelay true
        socket.setTimeout @timeout

        socket.on 'connect', (() =>
          @_base.debug("Connected to #{host}:#{port}.")
          socket.write "0" + inverterId + "*\r\n"
        )

        socket.on 'data', ((data) =>
          @_base.debug("Received raw data:", data)

          rawData = data.toString 'utf8'
          values = rawData.split ","

          if values.length >= 20
            @_base.resetLastError()
            @emit "solarViewData", values

          socket.end()
          resolve()
        )

        socket.on 'error', (error) =>
          if error.code == 'ETIMEDOUT'
            newError = "Timeout fetching SolarView data"
          else
            newError = "Error fetching SolarView data: " + error.toString()

          socket.destroy()
          reject newError

        socket.once 'timeout', () =>
          newError = "Timeout fetching SolarView data"
          socket.destroy()
          reject newError


    # poll device according to interval
    requestUpdate: ->
      @fetchData(@host, @port, @inverterId)
        .catch (error) =>
          @_base.error error
        .finally () =>
          @_base.scheduleUpdate @requestUpdate, @interval

    
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
        description: "Energy Yield of Current Year"
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

    _energyToday: 0.0
    _energyMonth: 0.0
    _energyYear: 0.0
    _energyTotal: 0.0
    _currentPower: 0.0

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      super(@config, @plugin, lastState)
      @_base.debug("SolarViewInverterSimpleDevice Initialization")

      @_energyMonth = lastState.energyMonth.value if lastState?.energyMonth?
      @_energyYear = lastState.energyYear.value if lastState?.energyYear?
      @_energyTotal = lastState.energyTotal.value if lastState?.energyTotal?

      @on 'solarViewData', ((values) ->
        @_base.setAttribute('energyToday', Number values[6])
        @_base.setAttribute('energyMonth', Number values[7])
        @_base.setAttribute('energyYear', Number values[8])
        @_base.setAttribute('energyTotal', Number values[9])
        @_base.setAttribute('currentPower', Number values[10])
      )

    getEnergyToday: -> Promise.resolve @_energyToday
    getEnergyMonth: -> Promise.resolve @_energyMonth
    getEnergyYear: -> Promise.resolve @_energyYear
    getEnergyTotal: -> Promise.resolve @_energyTotal
    getCurrentPower: -> Promise.resolve @_currentPower


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

    _gridVoltage: 0.0
    _gridAmperage: 0.0
    _inverterTemperature: 0.0

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      super(@config, @plugin, lastState)
      @_base.debug("SolarViewInverterDevice Initialization")

      @on 'solarViewData', ((values) ->
        @_base.setAttribute('gridVoltage', Number values[17])
        @_base.setAttribute('gridAmperage', Number values[18])
        @_base.setAttribute('inverterTemperature', Number values[19].replace /}+$/g, "")
      )

    getGridVoltage: -> Promise.resolve @_gridVoltage
    getGridAmperage: -> Promise.resolve @_gridAmperage
    getInverterTemperature: -> Promise.resolve @_inverterTemperature


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

    _dcVoltageStringA: 0.0
    _dcVoltageStringB: 0.0
    _dcVoltageStringC: 0.0
    _dcAmperageStringA: 0.0
    _dcAmperageStringB: 0.0
    _dcAmperageStringC: 0.0

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin, lastState) ->
      super(@config, @plugin, lastState)
      @_base.debug("SolarViewInverterWithMPPTrackerDevice Initialization")

      @on 'solarViewData', ((values) ->
        @_base.setAttribute('dcVoltageStringA', Number values[11])
        @_base.setAttribute('dcAmperageStringA', Number values[12])
        @_base.setAttribute('dcVoltageStringB', Number values[13])
        @_base.setAttribute('dcAmperageStringB', Number values[14])
        @_base.setAttribute('dcVoltageStringC', Number values[15])
        @_base.setAttribute('dcAmperageStringC', Number values[16])
      )

    getDcVoltageStringA: -> Promise.resolve @_dcVoltageStringA
    getDcVoltageStringB: -> Promise.resolve @_dcVoltageStringB
    getDcVoltageStringC: -> Promise.resolve @_dcVoltageStringC
    getDcAmperageStringA: -> Promise.resolve @_dcAmperageStringA
    getDcAmperageStringB: -> Promise.resolve @_dcAmperageStringB
    getDcAmperageStringC: -> Promise.resolve @_dcAmperageStringC


  # ###Finally
  # Create a instance of my plugin
  myPlugin = new SolarViewPlugin
  # and return it to the framework.
  return myPlugin