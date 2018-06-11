/* ================================================== //<>//
 
 Blob detection for infrared points - Tim Rolls 2016 - timrolls.com
 
 Up/Down arrows to set brightness threshold
 D to draw blobs
 Space to start drawing calibraticc2on polygon. Mouse clicks at corners. Space again to close shape. 
 Draw shape in this order: Top Left, Bottom Left, Bottom Right, Top Right. 
 C to show calibration polygon
 
 ================================================== */

import processing.video.*;
import blobDetection.*;

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

Capture cam;
BlobDetection theBlobDetection;
PImage img;
boolean newFrame=false;
boolean drawBlobs=true;
boolean calibrate=false;
boolean showCal=false;
boolean blur=true;
float threshold=0.4;
PShape poly;
PVector TLCorner, TRCorner, BLCorner, BRCorner;

int numBlobs=1; //maximum blobs to track

boolean isSketching = false;
boolean firstClick = false;
// PrintWriter output;
int oldX, oldY;


// ==================================================
// setup()
// ==================================================
void setup()
{
  // Size of applet
  size(640, 480);
  frameRate(30);
  // Capture
  cam = new Capture(this, 640, 480, "Camera", 30);
  //cam = new Capture(this, 640, 480, 30);
  // Comment the following line if you use Processing 1.5
  cam.start();

  // start oscP5, listening for incoming messages at port 12000
  oscP5 = new OscP5(this, 12001);
  myRemoteLocation = new NetAddress("127.0.0.1", 12000);

  // BlobDetection
  // img which will be sent to detection (a smaller copy of the cam frame);
  img = new PImage(640, 480); 
  theBlobDetection = new BlobDetection(img.width, img.height);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setConstants(numBlobs, 4000, 500);
  theBlobDetection.setThreshold(threshold); // will detect bright areas whose luminosity > 0.2f;

  poly = createShape();       //set up calibration polygon
} 


// ==================================================
// captureEvent()
// ==================================================
void captureEvent(Capture cam)
{
  cam.read();
  newFrame = true;
}

// ==================================================
// updateCorners()
// ==================================================
void updateCorners() {
  //set corner values to polygon vertex coords
  TLCorner = poly.getVertex(0);
  TRCorner =poly.getVertex(3);
  BLCorner = poly.getVertex(1);
  BRCorner = poly.getVertex(2);
}

// ==================================================
// draw()
// ==================================================
void draw()
{

  pushMatrix();
  //scale(-1, 1); //flip horiz
  //translate(-width,0);
  if (newFrame)
  {
    newFrame=false;
    image(cam, 0, 0, width, height);
    img.copy(cam, 0, 0, cam.width, cam.height, 
      0, 0, img.width, img.height);
    if (blur)fastblur(img, 2);
    theBlobDetection.setThreshold(threshold);
    theBlobDetection.computeBlobs(img.pixels);
    if (drawBlobs)drawBlobsAndEdges(true, true);
  }
  popMatrix();

  //scale(1, 1); //flip back
  if (showCal)shape(poly, 0, 0); //display calibration shape

  Blob b;
  b=theBlobDetection.getBlob(0); // get first blob

  //send osc when a blob is present
  if (b!=null) {

    float xmin, xmax, ymin, ymax;
    float blobX=b.x*width, blobY=b.y*height; //store blob coords (normalized)
    if (calibrate) {
      updateCorners();

      //map coords to calibration shape before sending (shape drawn TL, BL, BR, TR)
    float minY = map(blobX, TLCorner.x, TRCorner.x, TLCorner.y, TRCorner.y);
    float maxY = map(blobX, BLCorner.x, BRCorner.x, BLCorner.y, BRCorner.y);
    float minX = map(blobY, TLCorner.y, BLCorner.y, TLCorner.x, BLCorner.x);
    float maxX = map(blobY, TRCorner.y, BRCorner.y, TRCorner.x, BRCorner.x);
    float xFactor = map(blobX, minX, maxX, 0, 1);
    float yFactor = map(blobY, minY, maxY, 0, 1);

    PVector top = PVector.lerp(TLCorner, TRCorner, xFactor);
    PVector bottom = PVector.lerp(BLCorner, BRCorner, xFactor);
    PVector left = PVector.lerp(TLCorner, BLCorner, yFactor);
    PVector right = PVector.lerp(TRCorner, BRCorner, yFactor);

    float newx = map(blobX, left.x, right.x, 0, width);
    float newy = map(blobY, top.y, bottom.y, 0, height);

      //color mouse red
      stroke(255, 0, 0);
      strokeWeight(2);
      ellipse(b.x*width, b.y*height, 10, 10);

      //color transformed val green
      stroke(0, 255, 0);
      strokeWeight(2);
      ellipse(newx, newy, 10, 10);
      text( newx+", "+ newy, 10, 28);

      OscMessage myMessage = new OscMessage("/blobLocCal");
      myMessage.add(newx/width); //normalize before sending
      myMessage.add(newy/height);
      /* send the message */
      oscP5.send(myMessage, myRemoteLocation);
    } 

    if (!calibrate) {
      OscMessage myMessage = new OscMessage("/blobLoc");
      myMessage.add(b.x); 
      myMessage.add(b.y);
      /* send the message */
      oscP5.send(myMessage, myRemoteLocation);
    }
  }

  frame.setTitle("Threshold: "+threshold+" || Draw Blobs: "+drawBlobs+" || FPS: "+(int)frameRate);
}


// ==================================================
// drawBlobsAndEdges()
// ==================================================
void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges)
{
  noFill();
  Blob b;
  EdgeVertex eA, eB;
  for (int n=0; n<theBlobDetection.getBlobNb (); n++)
  {
    b=theBlobDetection.getBlob(n);
    if (b!=null)
    {
      // Edges
      if (drawEdges)
      {
        strokeWeight(3);
        stroke(0, 255, 0);
        for (int m=0; m<b.getEdgeNb (); m++)
        {
          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);
          if (eA !=null && eB !=null)
            line(
              eA.x*width, eA.y*height, 
              eB.x*width, eB.y*height
              );
        }
      }

      // Blobs
      if (drawBlobs)
      {
        strokeWeight(1);
        stroke(255, 0, 0);
        rect(
          b.xMin*width, b.yMin*height, 
          b.w*width, b.h*height
          );
      }
      textSize(18);
      text( (int)(b.x*width)+", "+ (int)(b.y*height), 10, 28);
    }
  }
}