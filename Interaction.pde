// ==================================================
// mousePressed()
// ==================================================
void mousePressed() {
  if (isSketching == true) {
    poly.vertex(mouseX, mouseY);
    println(" vertex(" + mouseX + "," + mouseY +");");
    if (firstClick == true) {
      firstClick = false;
    } else {
      line(oldX, oldY, mouseX, mouseY);
    }
    oldX = mouseX;
    oldY = mouseY;
  }
}

// ==================================================
// keyPressed()
// ==================================================
void keyPressed() {
  switch(key) {
  case 'd':
    // toggle draw blobs
    drawBlobs=!drawBlobs;
    break;

  case 'b':
    // blur
    blur=!blur;
    break;

  case 'c':
    // show calibration shape
    showCal=!showCal;
    break;
  }
  
  //start calibration polygon, space again to end it
  if (key == ' ') {
    if (isSketching == false) {
      calibrate=false;
      showCal=true;
      poly = createShape();
      poly.beginShape();
      poly.stroke(255);
      poly.fill(255, 20);
      poly.strokeWeight(2);
      println(" beginShape();");
      firstClick = true;
      isSketching = true;
    } else {
      isSketching = false;
      poly.endShape(CLOSE);
      println("endShape(CLOSE);");
      calibrate=true; //calibrate results AFTER shape is closed
    }
  }

  if (keyCode == UP) threshold+=0.05 ;
  if (keyCode == DOWN && threshold>0.05) threshold-=0.05 ;
}