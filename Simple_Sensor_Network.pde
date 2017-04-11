/*
 * Draws a set of thermometers for incoming XBee Sensor data
 * by Rob Faludi http://faludi.com
 */

// used for communication via xbee api
import processing.serial.*; 

// Use Digi's library instead of http://code.google.com/p/xbee-api/
import com.digi.xbee.api.RemoteXBeeDevice;
import com.digi.xbee.api.XBeeDevice;
import com.digi.xbee.api.XBeeNetwork;
import com.digi.xbee.api.exceptions.XBeeException;
import com.digi.xbee.api.io.IOLine;
import com.digi.xbee.api.io.IOMode;
import com.digi.xbee.api.io.IOSample;
import com.digi.xbee.api.listeners.IIOSampleReceiveListener;

String version = "1.03";

// *** REPLACE WITH THE SERIAL PORT (COM PORT) FOR YOUR LOCAL XBEE ***
  private static final String PORT = "/dev/cu.usbserial-A9QDTN73";
  private static final int BAUD_RATE = 9600;
  
// create and initialize a new xbee object
XBeeDevice localDevice;

int error=0;

// make an array list of thermometer objects for display
ArrayList thermometers = new ArrayList();
// create a font for display
PFont font;

SensorData data = new SensorData();

void setup() {
  size(800, 600); // screen size
  smooth(); // anti-aliasing for graphic display

  // You’ll need to generate a font before you can run this sketch.
  // Click the Tools menu and choose Create Font. Click Sans Serif,
  // choose a size of 10, and click OK.
  font =  loadFont("SansSerif-10.vlw");
  textFont(font); // use the font for text

  // Print a list in case the selected one doesn't work out
  println("Available serial ports:");
  println(Serial.list());

  localDevice = new XBeeDevice(PORT, BAUD_RATE);
  try {
    localDevice.open();
  } catch(XBeeException e) {
    error = 1;
  }

  localDevice.addIOSampleListener(new IIOSampleReceiveListener() {
        @Override
        public void ioSampleReceived(RemoteXBeeDevice remoteDevice, IOSample ioSample) {
          println("New sample received from " + remoteDevice.get64BitAddress() +
              " - " + ioSample);
              data.value = ioSample.getAnalogValue(IOLine.DIO0_AD0);
              data.address = remoteDevice.get64BitAddress().toString();
        }
      });
}


// draw loop executes continuously
void draw() {
  background(224); // draw a light gray background
  // report any serial port problems in the main window
  if (error == 1) {
    fill(0);
    text("** Error opening XBee port: **\n"+
      "Is your XBee plugged in to your computer?\n" +
      "Did you set your COM port in the code near line 20?", width/3, height/2);
  }

  // check that actual data came in:
  if (data.value >=0 && data.address != null) { 

    // check to see if a thermometer object already exists for this sensor
    int i;
    boolean foundIt = false;
    for (i=0; i <thermometers.size(); i++) {
      if ( ((Thermometer) thermometers.get(i)).address.equals(data.address) ) {
        foundIt = true;
        break;
      }
    }

    // process the data value into a Celsius temperature reading for
    // LM335 with a 1/3 voltage divider
    //   (value as a ratio of 1023 times max ADC voltage times 
    //    3 (voltage divider value) divided by 10mV per degree
    //    minus zero Celsius in Kevin)
    float temperatureCelsius = (data.value/1023.0*1.2*3.0*100)-273.15;
    //println(" temp: " + round(temperatureCelsius) + "˚C");

    // update the thermometer if it exists, otherwise create a new one
    if (foundIt) {
      ((Thermometer) thermometers.get(i)).temp = temperatureCelsius;
    }
    else if (thermometers.size() < 10) {
      thermometers.add(new Thermometer(data.address,35,450,
      (thermometers.size()) * 75 + 40, 20));
      ((Thermometer) thermometers.get(i)).temp = temperatureCelsius;
    }

    // draw the thermometers on the screen
    for (int j =0; j<thermometers.size(); j++) {
      ((Thermometer) thermometers.get(j)).render();
    }
  }
} // end of draw loop


// defines the data object
class SensorData {
  int value;
  String address;
}


// defines the thermometer objects
class Thermometer {
  int sizeX, sizeY, posX, posY;
  int maxTemp = 40; // max of scale in degrees Celsius
  int minTemp = -10; // min of scale in degress Celcisu
  float temp; // stores the temperature locally
  String address; // stores the address locally

  Thermometer(String _address, int _sizeX, int _sizeY, 
  int _posX, int _posY) { // initialize thermometer object
    address = _address;
    sizeX = _sizeX;
    sizeY = _sizeY;
    posX = _posX;
    posY = _posY;
  }

  void render() { // draw thermometer on screen
    noStroke(); // remove shape edges
    ellipseMode(CENTER); // center bulb
    float bulbSize = sizeX + (sizeX * 0.5); // determine bulb size
    int stemSize = 30; // stem augments fixed red bulb 
    // to help separate it from moving mercury
    // limit display to range
    float displayTemp = round( temp);
    if (temp > maxTemp) {
      displayTemp = maxTemp + 1;
    }
    if ((int)temp < minTemp) {
      displayTemp = minTemp;
    }
    // size for variable red area:
    float mercury = ( 1 - ( (displayTemp-minTemp) / (maxTemp-minTemp) )); 
    // draw edges of objects in black
    fill(0); 
    rect(posX-3,posY-3,sizeX+5,sizeY+5); 
    ellipse(posX+sizeX/2,posY+sizeY+stemSize, bulbSize+4,bulbSize+4);
    rect(posX-3, posY+sizeY, sizeX+5,stemSize+5);
    // draw grey mercury background
    fill(64); 
    rect(posX,posY,sizeX,sizeY);
    // draw red areas
    fill(255,16,16);

    // draw mercury area:
    rect(posX,posY+(sizeY * mercury), 
    sizeX, sizeY-(sizeY * mercury));

    // draw stem area:
    rect(posX, posY+sizeY, sizeX,stemSize); 

    // draw red bulb:
    ellipse(posX+sizeX/2,posY+sizeY + stemSize, bulbSize,bulbSize); 

    // show text
    textAlign(LEFT);
    fill(0);
    textSize(10);

    // show sensor address:
    text(address, posX-10, posY + sizeY + bulbSize + stemSize + 4, 65, 40);

    // show maximum temperature: 
    text(maxTemp + "˚C", posX+sizeX + 5, posY); 

    // show minimum temperature:
    text(minTemp + "˚C", posX+sizeX + 5, posY + sizeY); 

    // show temperature:
    text(round(temp) + " ˚C", posX+2,posY+(sizeY * mercury+ 14));
  }
}
