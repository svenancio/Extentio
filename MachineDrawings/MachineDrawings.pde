/*
  Extentio - Machine Drawings, Human Desires
  by Sergio Venancio
  Version 1.5b - 2019

  This software is free; you can redistribute it and/or
  modify it under the terms of the GNU General Public
  License version 3 as published by the Free Software Foundation.
  
  This software is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  General Public License for more details.

  _______________________
  
  This software makes automated drawings based on webcamera information, and
  has 4 objectives: OBSERVE, DRAW, EVALUATE and EVOLVE. More about this project
  in README.md file
  
  Current Features:
  - OBSERVE: photo processing
  - OBSERVE: multiple face detection
  - OBSERVE: random face selection and crop
  - DRAW: face model of points
  - DRAW: selection of color palette based on selected face
  - DRAW: random direction short straight lines
  
  New Features:
  - EVALUATE: stops drawing if detects face while drawing
  - OBSERVE: double face detection for better accuracy
    
  Next Possible Features:
  - OBSERVE: edge detection for guidelines
  - DRAW: color palette based on histogram division
  - DRAW: drawing based on attractors
  - EVALUATE: density of lines 
*/

import processing.video.*;
import processing.pdf.*;
import org.opencv.core.Core;


/* 
  OPTIONS
  Change the following parameters to adjust observation, drawing and evaluation
*/

boolean debugMode = false; //use debug mode to calibrate camera
int brightness = 10;//set brightness from 0 to 255
float contrast = 1.5;//set contrast from 0.0 to 2.0
int maxDrawTime = 9000;//in frames (1800 equals 1 minute)
int faceSizeThreshold = 10;//minimum size of a face, considered during main detection
int secondThreshold = 360;//minimum size of a face, considered during redetection for validation
boolean doubleDetect = true;//use this for better accuracy in face detection
int brushTech = 1;//1 - random stroke size brush; 2 - lines; 3 - circles;

/* END OPTIONS */

Capture cam;
FaceDetection fd;
Rectangle faceDetected;

PImage img, dbg;

//during a drawing, this pixel map will tell which pixels are already filled
boolean[][] drawn;

ArrayList<Pen> pens = new ArrayList();

/*
 * this model uses a predefined set of starting points for the pens. 
 * Add more to raise the density of the drawing (it costs CPU)
*/
PVector[] faceModel = {
new PVector(359, 388),
new PVector(296, 334),
new PVector(432, 330),
new PVector(291, 289),
new PVector(434, 279),
new PVector(280, 423),
new PVector(450, 420),
new PVector(361, 471),
new PVector(341, 407),
new PVector(379, 406),
new PVector(355, 222),
new PVector(220, 346),
new PVector(507, 344),
new PVector(370, 686),
new PVector(365, 604),
new PVector(353, 141),
new PVector(473, 189),
new PVector(238, 189),
new PVector(161, 676),
new PVector(582, 676)
};

boolean photoTaken;
int photoCount;


BrightnessContrastController bc;

int StopCount = maxDrawTime;


String session;

void setup() {
  //fullScreen();
  size(720,720);
  frameRate(30);
  
  System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
  
  session = year()+""+month()+""+day()+"_"+hour()+""+minute();
  
  drawn = new boolean[width][height];
  bc = new BrightnessContrastController(); 
  
  String[] cameras = Capture.list();
  for (int i = 0; i < cameras.length; i++) {
    println(i + " " + cameras[i]);
  }
  
  //change the next line to set up your camera. The scope is 
  //(this, width, height, name (just change the number inside []), framerate)
  cam = new Capture(this, 1920, 1080, cameras[139], 30);
  cam.start();
  
  fd = new FaceDetection(this, cam);
  
  photoTaken = false;
  photoCount = 0;
  
  setBackground();
}

void setBackground() {
  background(0);
  noStroke();
  fill(255);
  rect(width/2 - height/2,0,height,height);
  noFill();
}

//update the camera source
void captureEvent(Capture cam) {
  if(!photoTaken) {
    cam.read();
  }
}

void draw() {
  if(debugMode) {
    performCalibration();
  } else {
    if(photoTaken) {
      if(StopCount > 0){
        StopCount--;
        
        for (Pen d: pens) {
          d.draw();
        }
        
        //finish drawing by time
        if(StopCount == 0) {
          println("stopping by time");
          finishDrawing();
        }
        
        //try to detect another face while drawing, in order to stop it
        if(StopCount % 30 == 0) {
          thread("redetect");
          
          if(fd.faceRedetected && StopCount < maxDrawTime*0.7) {
            println("stopping by face redetection");
            finishDrawing();
          }
        }
      }
    } else {
      if(second() % 2 == 0) {
        
        //try to detect a face
        fd.detectRandom(cam, doubleDetect);
        
        //if found a face
        if(fd.focusImg != null) {
          img = fd.focusImg.get();
           
          //apply brightness and contrast
          img = bc.nondestructiveShift(img, brightness, contrast);
            
          photoTaken = true;
          StopCount = maxDrawTime;
          println("starting drawing");
          
          for (int i = 0;i<faceModel.length;i++) {
            color c = getColorFromPixel(new PVector(faceModel[i].x,faceModel[i].y));
            Pen p = new Pen(new PVector(faceModel[i].x, faceModel[i].y), 30, c);
            pens.add(p);
            
            p = new Pen(new PVector(faceModel[i].x+(random(-10,10)), faceModel[i].y+(random(-10,10))), 30, c);
            pens.add(p);
          }
        }
      }
    }
  }
}



void redetect() {
  fd.drawingDetect(get());
}

void finishDrawing() {
  photoTaken = false;
  
  save(session+"_d"+photoCount+".png");
  photoCount++;
  
  drawn = new boolean[width][height];
  pens = new ArrayList();
  
  setBackground();
}


/***************UTILS*****************/

void performCalibration() {
  image(cam,0,0);
  fd.showDetectedFaces(cam);
  fd.detectRandom(cam, false);
  
  if(fd.focusImg != null) {
    fd.focusImg.resize(100,100);
    image(fd.focusImg,width-100,height-100);
  }
}

//pick a pixel with the closest color inside a range 
PVector getNearbyPixel(PVector v, int size, color c) {
  PVector result = new PVector(v.x, v.y); //it will return the same pixel if none is found
  int diff = 9999999;
  int tempDiff;
  ArrayList<PVector> closeColors = new ArrayList<PVector>();
  
  //first, check image boundaries
  if (isCoord(v,img)) {
    //defines the comparison area
    PVector min = new PVector(v.x - size, v.y - size);
    PVector max = new PVector(v.x + size, v.y + size);
    
    //constrain max and min values to avoid canvas overflow  
    min.x = constrain(min.x, width/2-height/2, (width/2+height/2)-1);
    min.y = constrain(min.y, 0, height-1);
    max.x = constrain(max.x, width/2-height/2, (width/2+height/2)-1);
    max.y = constrain(max.y, 0, height-1);

    //for each pixel of the comparison area...
    for (int x = (int)min.x; x <= max.x; x++) {
      for (int y = (int)min.y; y <= max.y; y++) {
        //check if it has not been filled already
        if(!drawn[x][y]) {
          //store a temporary color distance between the original pixel and the destiny
          tempDiff = getColorDistance(getColorFromPixel(new PVector(x, y)), c);
          
          //if temporary distance is lower than before 
          if (tempDiff < diff) {
            //update the closest distance
            diff = tempDiff; 
            closeColors.clear();//clear closest color candidates because there is a closer one
            closeColors.add(new PVector(x,y));
          }
          else if(tempDiff == diff) {
            //if distance is the same, each pixel is considered a candidate
            closeColors.add(new PVector(x,y));
          }
        }
      }
    }
    
    //if there is more than one pixel as a candidate for closest color, select one randomly
    if(closeColors.size() > 0) {
      int chosen = floor(random(0,closeColors.size()));
      if(chosen == closeColors.size()) chosen--;//limit correction
      result.x = closeColors.get(chosen).x;
      result.y = closeColors.get(chosen).y;
    }
  }  
  
  //mark this pixel as "filled" in the canvas table
  drawn[(int)result.x][(int)result.y] = true;
  
  //returns the destiny pixel
  return result;
}

//check if this coordinates are within the limits of the image
boolean isCoord(PVector v, PImage imag) {
  if (v.x >= 0 && v.x < imag.width &&
    v.y >= 0 && v.y < imag.height) {
    return true;
  } 
  else {
    return false;
  }
}

//return pixel color from its coordinates
color getColorFromPixel(PVector v) {
  return img.pixels[(int)(v.x + v.y * img.width)];
}

//compare two colors (this code is based on Processing tutorials) 
int getColorDistance(int c1, int c2) 
{
  //bit shifting is faster than Color() methods
  int c1R = (c1 >> 16) & 0xFF; 
  int c1G = (c1 >> 8) & 0xFF;
  int c1B = c1 & 0xFF;

  int c2R = (c2 >> 16) & 0xFF; 
  int c2G = (c2 >> 8) & 0xFF;
  int c2B = c2 & 0xFF;

  int distance  = 0;
  
  //we use square to normalize values
  distance += Math.pow(c1R - c2R, 2);
  distance += Math.pow(c1G - c2G, 2);
  distance += Math.pow(c1B - c2B, 2);
  
  return distance;
} 
/*********************************/
