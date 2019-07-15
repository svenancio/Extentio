import gab.opencv.*;
import java.awt.Rectangle;


class FaceDetection {
  private OpenCV opencv, opencv2;
  private Rectangle[] faces;
  private int size, faceSelected;

  public PImage focusImg;
  public PVector rEyeCenter, lEyeCenter, nose;
  public boolean faceRedetected;
  
  public FaceDetection(PApplet context, Capture came) {
    //two instances of openCV, one for camera, the other for drawing
    opencv = new OpenCV(context, came.width, came.height);
    opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
    
    opencv2 = new OpenCV(context, width, height);
    opencv2.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  }
  
  public void detectBiggest(PImage came, boolean doubleDetect) {
    faceSelected = -1;
    focusImg = null;//before every detection, empty the target image
     
    opencv.loadImage(came);
    faces = opencv.detect();
    
    //if any faces are found
    if (faces != null && faces.length > 0) {
      size = 0;
      //select the biggest one
      for(int i=0;i<faces.length;i++) {
        if(faces[i].width > size && faces[i].width > faceSizeThreshold) {
          faceSelected = i;
          size = faces[i].width;
        }
      }
      
      //frame the target image
      focusImg = came.get(faces[faceSelected].x - size/2, faces[faceSelected].y - size/2, size*2, size*2);
      focusImg.resize(height,height);
      
      if(doubleDetect) {
        opencv.loadImage(focusImg);
        faces = opencv.detect();
        
        if (faces != null && faces.length > 0) {
          size = 0;
          
          for(int i=0;i<faces.length;i++) {
            if(faces[i].width > secondThreshold) {
              faceSelected = i;
              size = faces[i].width;
            }
          }
          
          //if can't detect for the second time, empty the target image
          if(size == 0) focusImg = null; 
        }
      }
    }
  }
  
  public void detectRandom(PImage came, boolean doubleDetect) {
    faceSelected = -1;
    focusImg = null;//before every detection, empty the target image
     
    opencv.loadImage(came);
    faces = opencv.detect();
    
    //if any faces are found
    if (faces != null && faces.length > 0) {
      //select a random one
      faceSelected = floor(random(faces.length));
      size = faces[faceSelected].width;
      
      //frame the target image
      focusImg = came.get(faces[faceSelected].x - size/2, faces[faceSelected].y - size/2, size*2, size*2);
      focusImg.resize(height,height);
      
      if(doubleDetect) {
        opencv.loadImage(focusImg);
        faces = opencv.detect();
        
        
        if (faces != null && faces.length > 0) {
          size = 0;
          //if the biggest detected face is bigger than the threshold, than double detection occurs
          for(int i=0;i<faces.length;i++) {
            if(faces[i].width > secondThreshold && faces[i].width > size) {
              faceSelected = i;
              size = faces[i].width;
            }
          }
          
          //if can't detect for the second time, empty the target image
          if(size == 0) focusImg = null; 
        }
      }
    }
  }
  
  public void drawingDetect(PImage drw) {
    faceRedetected = false;
     
    opencv2.loadImage(drw);
    faces = opencv2.detect();
    
    if (faces != null && faces.length > 0) {
      //picks the biggest face
      for(int i=0;i<faces.length;i++) {
        if(faces[i].width > width*0.5) {
          faceRedetected = true;
        }
      }
    }
  }
  
  //for debug purposes, use this to view all the detected face on an image
  public void showDetectedFaces(PImage img) {
    faceSelected = -1;
    focusImg = null;
    
    opencv.loadImage(img);
    faces = opencv.detect();
    
    if (faces != null && faces.length > 0) {
      for(int i=0;i<faces.length;i++) {
        strokeWeight(2);
        stroke(255,0,0);
        noFill();
        rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
      }
    }
  }
}
