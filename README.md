# bwsn-examples
Example code from book Building Wireless Sensor Networks

The example project "Simple sensor network" in Chapter 5 doesn't work with the newer Processing, because the xbee-api library (http://code.google.com/p/xbee-api/) used by the sketch has some dependencies that are not supported by Processing any more. Some suggest to downgrade to Processing 1.5.1 to make the example work, which I failed on trying due to another weird Java issue (on Mac OSX), so I decided to take another approach: change the code to work with the (new?) Java API provided by Digi (creator of XBee modules).

The library can be downloaded from https://github.com/digidotcom/XBeeJavaLibrary/releases. Take these steps after unzipping it to some directory:
  1. Copy xbee-java-library-1.2.0.jar to the code directory with the sketch
  2. Copy rxtx-2.2.jar, slf4j-api-1.7.12.jar, and slf4j-nop-1.7.12.jar from extra-libs directory to the above code directory
  3. Copy extra-libs/native/Mac_OS_X/librxtxSerial.jnilib (per your OS) to the same code directory
