import processing.opengl.*;
import oscP5.*;
import netP5.*;
import proxml.*;
import ddf.minim.*;

//~~~~~~~~~~~~~~~~~~

int masterFileCounter=0;
String[] allFiles;

int sW = 640;
int sH = 480;
int fps = 24;
int counter = 0;
int counterMax = 0; //number of MocapFrames to record
Countdown countdown;

String sayText = "";
String sayTextPrefix = "";
String sayTextSeparator = "  ...  ";

Minim minim;
OscP5 oscP5;
boolean found=false;

XMLInOut xmlIO;
//proxml.XMLElement xmlFile;
proxml.XMLElement MotionCapture;
String xmlFileName = "mocapData";
String xmlFileType = "xml";
String xmlFilePath = "savexml";
String aeFileName = "aeMocapData";
String aeFilePath = "saveae";
String aeFileType = "txt";

boolean limitReached = false;
boolean loaded = false;

String[] oscNames = {
  //~~~   complete list of working Joints, check updates at https://github.com/Sensebloom/OSCeleton  ~~~
  "head", "neck", "torso", "r_shoulder", "r_elbow", "r_hand", "l_shoulder", "l_elbow", "l_hand", "r_hip", "r_knee", "r_foot", "l_hip", "l_knee", "l_foot"
    //~~~
  //"r_hand","r_wrist","r_elbow","r_shoulder", "l_hand","l_wrist","l_elbow","l_shoulder","head","torso"
};

File dataFolder;
Data data;
int[] pinNums = new int[oscNames.length];
proxml.XMLElement[] oscXmlTags = new proxml.XMLElement[oscNames.length];
float posX, posY, posZ;

float[] x = new float[oscNames.length];
float[] y = new float[oscNames.length];
float[] z = new float[oscNames.length];
float depth = 200;
int circleSize = 50;

Button[] buttons = new Button[5];

boolean modeRec = false;
boolean modeOsc = false;
boolean modePlay = false;
boolean modeExport = false;
boolean modeStop = true;
boolean needsSaving = false;

//~~~~~~~~~~~~~~~~~~

void setup() {
  size(sW, sH, OPENGL);
  frameRate(fps);
  dataFolder = new File(sketchPath, "data" + "/" + xmlFilePath + "/");
  allFiles = dataFolder.list();
  for(int i=0;i<allFiles.length;i++){
  if (allFiles[i].toLowerCase().endsWith(xmlFileType)) {
  masterFileCounter++;
  }
  }
  //masterFileCounter = allFiles.length;
  if(masterFileCounter==1){
    sayTextPrefix = masterFileCounter + " existing saved XML file";
  }else{
    sayTextPrefix = masterFileCounter + " existing saved XML files";
  }
  ellipseMode(CENTER);
  minim = new Minim(this);
  oscP5 = new OscP5(this, "127.0.0.1", 7110);
  buttons[0] = new Button(25, height-20, 30, color(240, 10, 10), 12, "rec");
  buttons[1] = new Button(60, height-20, 30, color(200, 20, 200), 12, "osc");
  buttons[2] = new Button(width-25, height-20, 30, color(50, 50, 220), 12, "save");
  buttons[3] = new Button(width-60, height-20, 30, color(20, 200, 20), 12, "play");
  buttons[4] = new Button(95, height-20, 30, color(100, 100, 100), 12, "stop");
  xmlPlayerInit(masterFileCounter);
  xmlRecorderInit();
  countdown = new Countdown(8, 2);
  background(0);
}

//~~~


void draw() {
  background(0);
  if (modeRec||modeOsc) {
    xmlRecorderUpdate();
  }
  if (modePlay) {
    xmlPlayerUpdate();
  }
  buttonHandler();
  recDot();
  sayText = xmlFileName + (masterFileCounter);
  //println(counter);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void buttonHandler() {
  for (int i=0;i<buttons.length;i++) {
    buttons[i].checkButton();
    buttons[i].drawButton();
  }
  if (buttons[0].clicked) {
    modesRefresh();
    xmlRecorderInit();
    modeRec = true;
    if (!needsSaving) {
      needsSaving = true;
      masterFileCounter++;
    }
    sayTextPrefix = "Recording skeleton data";
  }
  else if (buttons[1].clicked) {
    modesRefresh();
    xmlRecorderInit();
    modeOsc = true;
    if (!needsSaving) {
      needsSaving = true;
      masterFileCounter++;
    }
    sayTextPrefix = "Recording OSC data";
  }
  else if (buttons[2].clicked) {
    modesRefresh();
    modeExport = true;
    aePinSaveToDisk(masterFileCounter);    
    sayTextPrefix = "Exporting all XML files for After Effects";
  }
  else if (buttons[3].clicked) {
    modesRefresh();
    if (needsSaving) {
      xmlSaveToDisk();
    }
    modePlay = true;
    sayTextPrefix = "Playing back last saved XML file";
  }
  else if (buttons[4].clicked) {
    countdown.foo.play();
    modesRefresh();
    if (needsSaving) {
      xmlSaveToDisk();
    }
    needsSaving=false;
    sayTextPrefix = "Click PLAY to review, SAVE to export for After Effects";
  }
}

void buttonsRefresh() {
  for (int i=0;i<buttons.length;i++) {
    buttons[i].clicked = false;
  }
}

void modesRefresh() {
  countdown = new Countdown(8, 2);
  buttonsRefresh();
  counter=0;
  modeRec = false;
  modeOsc = false;
  modePlay = false;
  modeExport = false; 
  modeStop=false;
}

void recDot() {
  fill(200);
  textAlign(LEFT);
  text(sayTextPrefix + sayTextSeparator + sayText, 40, 35);
  text(int(frameRate) + " fps", sW-60, 35);
  noFill();
  if (counter%2!=0) {
    if (modeRec) {
      stroke(255, 20, 0);
    }
    else if (modeOsc) {
      stroke(225, 0, 205);
    }
    else if (!modeRec&&!modeOsc) {
      stroke(35, 25, 35);
    }
  } 
  else {
    stroke(35, 25, 35);
  }
  strokeWeight(20);
  point(20, 30);
  stroke(200);
  strokeWeight(1);
  rectMode(CORNER);
  rect(3, 59, 633, 360);
  line((sW/2)-10, (sH/2), (sW/2)+10, (sH/2));
  line((sW/2), (sH/2)-10, (sW/2), (sH/2)+10);
}

void stop() {
  countdown.stop();
  minim.stop();
  super.stop();
  exit();
}
