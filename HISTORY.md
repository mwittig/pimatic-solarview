# Release History

* 20150406, V0.0.1
    * Initial Version
* 20150406, V0.0.2
    * Removed some test code. Fixed typo
* 20150406, V0.0.3
    * NPM issues. Removed npm-debug.log
* 20150413, V0.0.4
    * Added debugging feature. Reduced logging output in normal mode. Updated README
* 20150416, V0.0.5
    * Improved attribute change. Now, a change event is triggered only, if a value has actually changed rather than
          triggering the change event at each interval
* 20150429, V0.0.6
    * Added license section in `package.json`. 
    * Added support for xLink and xAttributeOptions as part of the device configuration
    * Fixed some typos, added version badge, added screenshots
* 20150509, V0.0.7
    * Bug fix: destroy socket on error to release socket descriptor
* 20150526, V0.0.8
    * Reduced error log output. If "debug" is not set on the plugin, only new error states will be logged
    * Minor changes
* 20150529, V0.0.9
    * Fixed bug controlling the error output
    * Added socket timeout handling to avoid a large number of pending sockets if TCP timeout applies and the 
      interval is shorter than the TCP timeout
* 20151215, V0.8.0
    * Moved history to separate file
    * Now using pimatic-plugin-commons helper functions
    * Changed strategy for requesting updates
* 20160106, V0.8.1    
    * Bug fix: Fixed handling of attribute values which led to false results in some cases
    * Added recovery of energyMonth, energyYear, and energyTotal values from database 
    * Added travis build descriptor
* 20160305, V0.8.2    
    * Dependency Updates
    * Added travis build badge
* 20160316, V0.8.3    
    * Bug fix: Fixed fetchData() handler being pending forever if server closes the connection without returning data
    * Moved release history to separate file
    * Provide a SPDX 2.0 license identifier as required by npm v2.1 guidelines on 
      license metadata - see also https://github.com/npm/npm/releases/tag/v2.10.0
    * Added license info to README
* 20160322, V0.8.4
    * Fixed compatibility issue with Coffeescript 1.9 as required for pimatic 0.9
    * Updated peerDependencies property for compatibility with pimatic 0.9
* 20160419, V0.8.5
    * Added destroy method to cancel an scheduled update when the device is removed or updated