class Pen {
  color c;//pen color
  PVector porig = new PVector(width/2, height/2);
  PVector pdest = new PVector(); 
  int areaSize = 100; //caution: by raising this value, you'll need more CPU
  boolean drawing = true;
  
  public Pen(PVector start, int size, color co) {
    porig = start;
    areaSize = size;
    c = co;
  }

  public void draw() {
    if(drawing) {
      pdest = getNearbyPixel(porig, areaSize, c);
      if(porig.x == pdest.x && porig.y == pdest.y) {
        drawing = false;
        return;
      }
      
      if(brushTech == 1) {
        lightBrushTechnique();
      } else if(brushTech == 2) {
        lightLineTechnique();
      } else if(brushTech == 3) {
        lightCircleTechnique();
      } else {
        lightBezierTechnique();
      }

      porig.x = pdest.x;  
      porig.y = pdest.y;
    }
  }
  
  //PINCEIS
  public void lightBrushTechnique() {
    stroke(c & 0x30FFFFFF);
    strokeWeight(random(2,5));
    strokeCap(ROUND);
    strokeJoin(ROUND);
    line(porig.x, porig.y, pdest.x, pdest.y);
  }
  
  public void lightLineTechnique() {
    stroke(c);
    line(porig.x, porig.y, pdest.x, pdest.y);
  }
  
  public void lightCircleTechnique() {
    int radius = round(dist(pdest.x, pdest.y, porig.x, porig.y));
    ellipseMode(CENTER);
    fill(c & 0x10FFFFFF);
    noStroke();
    ellipse(porig.x, porig.y, radius, radius);
  }
  
  public void lightBezierTechnique() {
    noFill();
    stroke(c & 0x30FFFFFF);
    bezier(porig.x+width/2,porig.y,porig.x+(random(4)-2)+width,porig.y+(random(4)-2),pdest.x+(random(4)-2)+width,pdest.y+(random(4)-2),pdest.x,pdest.y);
  }
}
