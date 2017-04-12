/*
 * Draws a set of switches for managing XBee Actuators
 * by Rob Faludi http://faludi.com
 */

// used for communication via xbee api
import processing.serial.*; 

import com.digi.xbee.api.RemoteXBeeDevice;
import com.digi.xbee.api.XBeeDevice;
import com.digi.xbee.api.XBeeNetwork;
import com.digi.xbee.api.exceptions.XBeeException;
import com.digi.xbee.api.io.IOLine;
import com.digi.xbee.api.listeners.IDiscoveryListener;

String version = "1.02";

// *** REPLACE WITH THE SERIAL PORT (COM PORT) FOR YOUR LOCAL XBEE ***
String PORT = "/dev/cu.usbserial-A9QDTN73";
int BAUD_RATE = 9600;

int error=0;

// make an array list of thermometer objects for display
ArrayList switches = new ArrayList();
ArrayList nodes = new ArrayList();

// create a font for display
PFont font;
float lastNodeDiscovery;

XBeeDevice localDevice;

void setup() {

  size(800, 230); // screen size
  smooth(); // anti-aliasing for graphic display

  // You’ll need to generate a font before you can run this sketch.
  // Click the Tools menu and choose Create Font. Click Sans Serif,
  // choose a size of 10, and click OK.
  font =  loadFont("SansSerif-10.vlw");
  textFont(font);

  // Print a list in case the selected serial port doesn't work out
  println("Available serial ports:");
  println(Serial.list());
  try {
    localDevice = new XBeeDevice(PORT, BAUD_RATE);
    localDevice.open();
    
    XBeeNetwork network = localDevice.getNetwork();
    network.addDiscoveryListener(new IDiscoveryListener() {
      public void deviceDiscovered(RemoteXBeeDevice discoveredDevice) {
        println("Device discovered: " + discoveredDevice);
        nodes.add(discoveredDevice);
      }
      
      public void discoveryError(String error) {}
      
      public void discoveryFinished(String error) {}
    });
  }
  catch (XBeeException e) {
    println("");
    println("  ** Error opening XBee port: " + e + " **");
    println("");
    println("Is your XBee plugged in to your computer?");
    println("Did you set your COM port in the code near line 30?");
    error=1;
  }

  // run a node discovery to find all the radios currently on the network
  //  (this assumes that all the network radios are Actuator nodes)
  nodeDiscovery();
  lastNodeDiscovery = millis(); // note the time when the discovery was made
}


// draw loop executes continuously
void draw() {

  background(255); // draw a white background

  // report any serial port problems in the main window
  if (error == 1) {
    fill(0);
    text("** Error opening XBee port: **\n"+
      "Is your XBee plugged in to your computer?\n" +
      "Did you set your COM port in the code near line 27?", 
      width/3, height/2);
  }

  // create a switch object for each node that doesn't have one yet
  // ...and get current state of every new node
  for (int j=0; j < nodes.size(); j++) {
    RemoteXBeeDevice device = (RemoteXBeeDevice) nodes.get(j);
    XBee64BitAddress address64 = device.get64BitAddress();
    int i = 0;
    boolean foundIt = false;
    for (i=0; i < switches.size(); i++) {
      if  ( ((Switch) switches.get(i)).addr64.equals(address64) ) {
        foundIt = true;
        break;
      }
    }

    // if the switch does not yet exist, create a new one
    // stop if there's more than can fit on the screen
    if (foundIt == false && switches.size() < 5) { 
      switches.add(new Switch(device, switches.size()));
      ((Switch) switches.get(i)).getState();
    }
  }


  // draw the switches on the screen
  for (int i =0; i<switches.size(); i++) {
    ((Switch) switches.get(i)).render();
  }


  // periodic node re-discovery
  if (millis() - lastNodeDiscovery > 15 * 60 * 1000) { // every 15 minutes
    nodeDiscovery();
    lastNodeDiscovery = millis();
  }
} // end of draw loop

void nodeDiscovery() {
  nodes.clear(); // reset node list, removing all old records
  switches.clear(); // reset switch list, removing all old records
  print ("cleared node list, looking up nodes...");
  
  XBeeNetwork network = localDevice.getNetwork();
  try {
    network.setDiscoveryTimeout(6000);
    network.startDiscoveryProcess();
  } catch (Exception e) {
    println("Discovery failed: " + e);
  }
}

// this function runs once every time the mouse is pressed
void mousePressed() {
  // check every switch object on the screen to see 
  // if the mouse press was within its borders
  // and toggle the state if it was (turn it on or off)
  for (int i=0; i < switches.size(); i++) {
    ((Switch) switches.get(i)).toggleState();
  }
}

// defines the switch objects and their behaviors
class Switch {
  RemoteXBeeDevice remoteDevice;
  int switchNumber, posX, posY;
  boolean state = false; // current switch state
  XBee64BitAddress addr64;  // stores the raw address locally
  String address;        // stores the formatted address locally
  PImage on, off;        // stores the pictures of the on and off switches


  // initialize switch object:
  Switch(RemoteXBeeDevice remoteDevice, int _switchNumber) { 
    this.remoteDevice = remoteDevice;
    on = loadImage("on.jpg");
    off = loadImage("off.jpg");
    addr64 = remoteDevice.get64BitAddress();
    switchNumber = _switchNumber;
    posX = switchNumber * (on.width+ 40) + 40;
    posY = 50;

    // parse the address int array into a formatted string
    String[] hexAddress = new String[addr64.getValue().length];
    for (int i=0; i<addr64.getValue().length;i++) {
      // format each address byte with leading zeros:
      hexAddress[i] = String.format("%02x", addr64.getValue()[i]); 
    }
    // join the array together with colons for readability:
    address = join(hexAddress, ":"); 

    println("Sender address: " + address);
  }

  void render() { // draw switch on screen
    noStroke(); // remove shape edges
    if(state) image(on, posX, posY); // if the switch is on, draw the on image
    else image(off, posX, posY);     // otherwise if the switch is off, 
                                     // draw the off image
    // show text
    textAlign(CENTER);
    fill(0);
    textSize(10);
    // show actuator address
    text(address, posX+on.width/2, posY + on.height + 10);
    // show on/off state
    String stateText = "OFF";
    fill (255,0,0);
    if (state) {
      stateText = "ON";
      fill(0,127,0);
    }
    text(stateText, posX + on.width/2, posY-8);
  }

  // checks the remote actuator node to see if its on or off currently
  void getState() {
    println("node to query: " + addr64);
    try {
      state = this.remoteDevice.getDIOValue(IOLine.DIO0_AD0) == IOValue.HIGH;
    } catch (XBeeException e) {
      println("Failed to get state from: " + addr64);
    }
  }

  // this function is called to check for a mouse click
  // on the switch object, and toggle the switch accordingly
  // it is called by the MousePressed() function so we already
  // know that the user just clicked the mouse somewhere
  void toggleState() {

    // check to see if the user clicked the mouse on this particular switch
    if(mouseX >=posX && mouseY >= posY && 
       mouseX <=posX+on.width && mouseY <= posY+on.height) {
         state = !state;
         try {
          remoteDevice.setDIOValue(IOLine.DIO0_AD0, state ? IOValue.HIGH : IOValue.LOW);
         } catch (XBeeException e) {
           println("Failed to set state to: " + addr64);
         }
    }
  }
} //end of switch class
