import ddf.minim.*; //<>// //<>// //<>//
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

// two-player model, each one has 8 directions
// add clock
// score
// survival mode
// add items
// change circle color
// change circle stoke

AudioPlayer introbgm, battlebgm, gameoverbgm, winbgm, eatbgm, bombbgm;
Minim minim;//audio context

PImage bg, player1, player2;
int bulletexist;
float bulletstartx, bulletendx, bulletstarty, bulletendy;
float startx, starty, endx, endy;

int soundnum;
int sizex, sizey;
int n, bgcolor, maxsize, gamemode, p1curdir, p2curdir;
int lastPressed = 0;
float p1x, p1y, p1z, p1belly, p1speed;
float p2x, p2y, p2z, p2belly, p2speed;
float[] xpos, ypos, ghost;
boolean start, assemble; // for game mode 2, check if two players are assembled

float[] p1color = new float[3];
float[] p2color = new float[3];
float[][] gcolor;

PGraphics pg1, pg2, pg3;

float c1x, c1y, c1w, c1h, c2x, c2y, c2w, c2h, c3x, c3y, c3w, c3h;

void setup() {
  size(960, 515);
  sizex = 1000;
  sizey = 600;
  bg = loadImage("rsz_bg.jpg");
  player1 = loadImage("player1.jpg");
  player2 = loadImage("player2.jpg");
  
  bulletexist = 0;
  frameRate(60);
  bgcolor = 210;
  maxsize = 100;
  soundnum = 0;
  
  minim = new Minim(this);
  introbgm = minim.loadFile("Mega Man (NES) Music - Select Screen.mp3", 2048); 
  battlebgm = minim.loadFile("Mega Man (NES) Music - Wily Battle.mp3", 2048);
  gameoverbgm = minim.loadFile("Mega Man (NES) Music - Game Over.mp3", 2048);
  winbgm = minim.loadFile("Mega Man (NES) Music - Ending Theme.mp3", 2048);
  eatbgm = minim.loadFile("eating in pacman (cut).mp3", 2048);
  bombbgm = minim.loadFile("Megaman Shootsound effects (cut).mp3", 2048);
  
  n = 20;
  
  p1x = sizex/2 - 100;
  p1y = sizey/2 - 100;
  p1z = 0;
  p1belly = 50;
  p1color[0] = random(255);
  p1color[1] = random(255);
  p1color[2] = random(255);
  
  
  p1speed = 1;
  
  p2x = sizex/2 + 100;
  p2y = sizey/2 - 100;
  p2z = 0;
  p2belly = 50;
  p2color[0] = random(255);
  p2color[1] = random(255);
  p2color[2] = random(255);
  
  p2speed = 1;
  
  assemble = false;
  
  xpos = new float[n];
  ypos = new float[n];
  ghost = new float[n];
  gcolor = new float[n][3];
  
  int i = 0;
  while (i < n) {
    xpos[i] = random(sizex);
    ypos[i] = random(sizey);
    ghost[i] = random(maxsize);
    gcolor[i][0] = random(255);
    gcolor[i][1] = random(255);
    gcolor[i][2] = random(255);
    
    if (sq(p1x-xpos[i])+sq(p1y-ypos[i]) > sq(10+(p1belly+ghost[i])/2) && sq(p2x-xpos[i])+sq(p2y-ypos[i]) > sq(10+(p2belly+ghost[i])/2)) {
      i++;
    }
  }
  
  start = false;
  gamemode = 0;
}

void draw() {
  
  background(bg);
 
  if (!bombbgm.isPlaying()){
    bombbgm.rewind();
  }
  
  switch (gamemode) {
    
    // game mode 1 --------------------------------------------------------------------------------
    case 1:
      introbgm.close();
      battlebgm.play();
      
      //background(bgcolor);
      fill(p1color[0], p1color[1], p1color[2]); 
      noStroke();
      ellipse(p1x, p1y, p1belly, p1belly);
      image(player1, p1x-p1belly/3, p1y-p1belly/3,p1belly*2/3,p1belly*2/3);

      // player moverment
      switch (p1curdir){
        case 1:
          p1x = p1x - p1speed;
        break;
        case 2:
          p1x = p1x + p1speed;
        break;
        case 3:
          p1y = p1y - p1speed;
        break;
        case 4:
          p1y = p1y + p1speed;
        break;
        default:
        break;
      }
      
      if (p1x < 0)
        p1x = 1000;
      if (p1x > 1000)
        p1x = 0;
      if (p1y < 0)
        p1y = 600;
      if (p1y > 600)
        p1y = 0;
      
      // end of player movement
      
      for (int i = 0; i < n; i++) {
        xpos[i] = xpos[i] + (p1x - xpos[i])/1000;
        ypos[i] = ypos[i] + (p1y - ypos[i])/1000;
        fill(gcolor[i][0], gcolor[i][1], gcolor[i][2]);
        ellipse(xpos[i], ypos[i], ghost[i], ghost[i]);
      }
      
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (i != j) {
            float[] update = eat(xpos[i], ypos[i], ghost[i],xpos[j], ypos[j], ghost[j]);
            xpos[i] = update[0];
            ypos[i] = update[1];
            ghost[i] = update[2];
            xpos[j] = update[3];
            ypos[j] = update[4];
            ghost[j] = update[5];
          }
        }
        
        float[] update = eatghost(xpos[i], ypos[i], ghost[i], p1x, p1y, p1belly);
        xpos[i] = update[0];
        ypos[i] = update[1];
        ghost[i] = update[2];
        p1x = update[3];
        p1y = update[4];
        p1belly = update[5];
        
        if (!eatbgm.isPlaying()) {
          eatbgm.rewind();
        }
        
        if (update[6] == 1) {
           eatbgm.play();
        }
                
      }
      followmouse();
      p2belly = 0;
      gameOver();
      
      if (bulletexist == 1) {
       println(startx, starty, endx, endy);
       strokeWeight(20); 
       fill(0);
       startx = startx + (bulletendx-bulletstartx)/20;
       starty = starty + (bulletendy-bulletstarty)/20;
       endx = endx + (bulletendx-bulletstartx)/20;
       endy = endy + (bulletendy-bulletstarty)/20;
       line(startx, starty, endx, endy);
       
       if (startx > sizex || starty > sizey || startx < 0 || starty < 0){
              bulletexist = 0;
       }
     }
     
    println(bulletexist);
    break;
    
    // game mode2 --------------------------------------------------------------------------------------
    case 2:
    
      introbgm.close();
      battlebgm.play();
      
      assemble = false;

      //background(bgcolor);
      fill(p1color[0], p1color[1], p1color[2]); 
      noStroke();
      ellipse(p1x, p1y, p1belly, p1belly);
      image(player1, p1x-p1belly/3, p1y-p1belly/3,p1belly*2/3,p1belly*2/3);
      
      fill(p2color[0], p2color[1], p2color[2]); 
      noStroke();
      ellipse(p2x, p2y, p2belly, p2belly);
      image(player2, p2x-p2belly/3, p2y-p2belly/3,p2belly*2/3,p2belly*2/3);
      
      // player moverment
      // player 1
      switch (p1curdir){
        case 1:
          p1x = p1x - p1speed;
        break;
        case 2:
          p1x = p1x + p1speed;
        break;
        case 3:
          p1y = p1y - p1speed;
        break;
        case 4:
          p1y = p1y + p1speed;
        break;
        default:
        break;
      }
      
      if (p1x < 0)
        p1x = sizex;
      if (p1x > sizex)
        p1x = 0;
      if (p1y < 0)
        p1y = sizey;
      if (p1y > sizey)
        p1y = 0;
        
      // player 2
      switch (p2curdir){
        case 1:
          p2x = p2x - p2speed;
        break;
        case 2:
          p2x = p2x + p2speed;
        break;
        case 3:
          p2y = p2y - p2speed;
        break;
        case 4:
          p2y = p2y + p2speed;
        break;
        default:
        break;
      }
      
      if (p2x < 0)
        p2x = sizex;
      if (p2x > sizex)
        p2x = 0;
      if (p2y < 0)
        p2y = sizey;
      if (p2y > sizey)
        p2y = 0;
      
      // end of player movement
      
      // ghost movement
      for (int i = 0; i < n; i++) {
        if (sq(xpos[i]-p1x)+sq(ypos[i]-p1y) < sq(xpos[i]-p2x)+sq(ypos[i]-p2y)) {
          xpos[i] = xpos[i] + (p1x - xpos[i])/1000;
          ypos[i] = ypos[i] + (p1y - ypos[i])/1000;
        }
        else {
          xpos[i] = xpos[i] + (p2x - xpos[i])/1000;
          ypos[i] = ypos[i] + (p2y - ypos[i])/1000;
        }    
        
        fill(gcolor[i][0], gcolor[i][1], gcolor[i][2]);
        ellipse(xpos[i], ypos[i], ghost[i], ghost[i]);
      }
      // end of ghost movement
      
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (i != j) {
            float[] update = eat(xpos[i], ypos[i], ghost[i],xpos[j], ypos[j], ghost[j]);
            xpos[i] = update[0];
            ypos[i] = update[1];
            ghost[i] = update[2];
            xpos[j] = update[3];
            ypos[j] = update[4];
            ghost[j] = update[5];
          }
        }
        
        float[] p1update = eatghost(xpos[i], ypos[i], ghost[i], p1x, p1y, p1belly);
        xpos[i] = p1update[0];
        ypos[i] = p1update[1];
        ghost[i] = p1update[2];
        p1x = p1update[3];
        p1y = p1update[4];
        p1belly = p1update[5];
        
        if (!eatbgm.isPlaying()) {
          eatbgm.rewind();
        }
        
        if (p1update[6] == 1) {
           eatbgm.play();
        }
        
        float[] p2update = eatghost(xpos[i], ypos[i], ghost[i], p2x, p2y, p2belly);
        xpos[i] = p2update[0];
        ypos[i] = p2update[1];
        ghost[i] = p2update[2];
        p2x = p2update[3];
        p2y = p2update[4];
        p2belly = p2update[5];
        
        if (!eatbgm.isPlaying()) {
          eatbgm.rewind();
        }
        
        if (p2update[6] == 1) {
           eatbgm.play();
        }
    
      }
      
      float[] fight = eateachother(p1x, p1y, p1belly, p2x, p2y, p2belly);
        p1x = fight[0];
        p1y = fight[1];
        p1belly = fight[2];
        p2x = fight[3];
        p2y = fight[4];
        p2belly = fight[5];
        
      //followmouse();
      gameOver();
    break;
    
    // game mode 3 ------------------------------------------------------------------------------------------
    case 3:
      introbgm.close();
      battlebgm.play();
    
      if (sq(p1x-p2x)+sq(p1y-p2y) < sq((p1belly+p2belly)/2)){
        assemble = true;
      }
      else {
        assemble = false;
      }
      
      //background(bgcolor);
      fill(p1color[0], p1color[1], p1color[2]); 
      noStroke();
      ellipse(p1x, p1y, p1belly, p1belly);
      image(player1, p1x-p1belly/3, p1y-p1belly/3,p1belly*2/3,p1belly*2/3);
      
      fill(p2color[0], p2color[1], p2color[2]); 
      noStroke();
      ellipse(p2x, p2y, p2belly, p2belly);
      image(player2, p2x-p2belly/3, p2y-p2belly/3,p2belly*2/3,p2belly*2/3);

      
      // player moverment
      // player 1
      
      if (!assemble) {
          switch (p1curdir){
            case 1:
              p1x = p1x - p1speed;
            break;
            case 2:
              p1x = p1x + p1speed;
            break;
            case 3:
              p1y = p1y - p1speed;
            break;
            case 4:
              p1y = p1y + p1speed;
            break;
            default:
            break;
          }
          if (p1x < 0)
            p1x = sizex;
          if (p1x > sizex)
            p1x = 0;
          if (p1y < 0)
            p1y = sizey;
          if (p1y > sizey)
            p1y = 0;
          
        // player 2
        switch (p2curdir){
          case 1:
            p2x = p2x - p2speed;
          break;
          case 2:
            p2x = p2x + p2speed;
          break;
          case 3:
            p2y = p2y - p2speed;
          break;
          case 4:
            p2y = p2y + p2speed;
          break;
          default:
          break;
        }
        
        if (p2x < 0)
          p2x = sizex;
        if (p2x > sizex)
          p2x = 0;
        if (p2y < 0)
          p2y = sizey;
        if (p2y > sizey)
          p2y = 0;
      }
      else { // if assemble
        if (p1belly >= p2belly){
          p2curdir = 0;
          switch (p1curdir){
            case 1:
              p1x = p1x - p1speed;
              p2x = p2x - p1speed;
            break;
            case 2:
              p1x = p1x + p1speed;
              p2x = p2x + p1speed;
            break;
            case 3:
              p1y = p1y - p1speed;
              p2y = p2y - p1speed;
            break;
            case 4:
              p1y = p1y + p1speed;
              p2y = p2y + p1speed;
            break;
            default:
            break;
          }
          
          if (p1x < 0)
            p1x = sizex;
          if (p1x > sizex)
            p1x = 0;
          if (p1y < 0)
            p1y = sizey;
          if (p1y > sizey)
            p1y = 0;
        }
        else {
          p1curdir = 0;
          switch (p2curdir){
              case 1:
                p1x = p1x - p2speed;
                p2x = p2x - p2speed;
              break;
              case 2:
                p1x = p1x + p2speed;
                p2x = p2x + p2speed;
              break;
              case 3:
                p1y = p1y - p2speed;
                p2y = p2y - p2speed;
              break;
              case 4:
                p1y = p1y + p2speed;
                p2y = p2y + p2speed;
              break;
              default:
              break;
            }
            
            if (p2x < 0)
              p2x = sizex;
            if (p2x > sizex)
              p2x = 0;
            if (p2y < 0)
              p2y = sizey;
            if (p2y > sizey)
              p2y = 0;
        }
      }
      // end of player movement
      
      // ghost movement
      for (int i = 0; i < n; i++) {
        if (sq(xpos[i]-p1x)+sq(ypos[i]-p1y) < sq(xpos[i]-p2x)+sq(ypos[i]-p2y)) {
          xpos[i] = xpos[i] + (p1x - xpos[i])/1000;
          ypos[i] = ypos[i] + (p1y - ypos[i])/1000;
        }
        else {
          xpos[i] = xpos[i] + (p2x - xpos[i])/1000;
          ypos[i] = ypos[i] + (p2y - ypos[i])/1000;
        }    
        
        fill(gcolor[i][0], gcolor[i][1], gcolor[i][2]);
        ellipse(xpos[i], ypos[i], ghost[i], ghost[i]);
      }
      // end of ghost movement
      
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (i != j) {
            float[] update = eat(xpos[i], ypos[i], ghost[i],xpos[j], ypos[j], ghost[j]);
            xpos[i] = update[0];
            ypos[i] = update[1];
            ghost[i] = update[2];
            xpos[j] = update[3];
            ypos[j] = update[4];
            ghost[j] = update[5];
          }
        }
        float[] p1update = eatghost(xpos[i], ypos[i], ghost[i], p1x, p1y, p1belly);
        xpos[i] = p1update[0];
        ypos[i] = p1update[1];
        ghost[i] = p1update[2];
        p1x = p1update[3];
        p1y = p1update[4];
        p1belly = p1update[5];
        
        if (!eatbgm.isPlaying()) {
          eatbgm.rewind();
        }
        
        if (p1update[6] == 1) {
           eatbgm.play();
        }
        
        float[] p2update = eatghost(xpos[i], ypos[i], ghost[i], p2x, p2y, p2belly);
        xpos[i] = p2update[0];
        ypos[i] = p2update[1];
        ghost[i] = p2update[2];
        p2x = p2update[3];
        p2y = p2update[4];
        p2belly = p2update[5];
        
        if (!eatbgm.isPlaying()) {
          eatbgm.rewind();
        }
        if (p2update[6] == 1) {
           eatbgm.play();
        }

      }
      
      //followmouse();
      gameOver();
    break;
    default:
      introbgm.play();
      //bgcolor = 210;
      PFont font;
      font = loadFont("ComicSansMS-48.vlw");
      textFont(font, 28);
      fill(255);
      text("PRESS 1: 1PLAYER", 300, 350);
      text("PRESS 2: 2PLAYER MODE A", 300, 400);
      text("PRESS 3: 2PLAYER MODE B", 300, 450);
    break;
  }
}

// ----------------------function-----------------------------------------------------------------------------

void keyPressed() {
  println("" + key);
  
  if (millis() - lastPressed > 100){
    lastPressed = millis();
    
    if (key == '1'){
      gamemode = 1;
      start = true;
    }
    if (key == '2'){
      gamemode = 2;
      start = true;
    }
    if (key == '3'){
      gamemode = 3;
      start = true;
    }

      // player 1 control
      if (key == 'a')
        p1curdir = 1;
      if (key == 'd') 
        p1curdir = 2;
      if (key == 'w') 
        p1curdir = 3;
      if (key == 's')
        p1curdir = 4;
        
      // player 2 control
      if (key == 'j')
        p2curdir = 1;
      if (key == 'l') 
        p2curdir = 2;
      if (key == 'i') 
        p2curdir = 3;
      if (key == 'k')
        p2curdir = 4;
    
    
    //// bomb  
    if (key == 'b') {
      bombbgm.play();
      float maxghost = max(ghost);
      for (int i = 0; i < ghost.length; i++){
        if (ghost[i] == maxghost) {
          ghost[i] = random(maxsize);
        }
      }
    }
    
    if (key == 'x') {
      bulletexist = 1;
      bulletstartx = p1x;
      bulletstarty = p1y;
      bulletendx = mouseX;
      bulletendy = mouseY;
      
      startx = p1x;
      starty = p1y;
      endx = p1x + (mouseX-p1x)/10;
      endy = p1y + (mouseY-p1y)/10;  
    }
  }
   
}

//void keyReleased() {
//  p1curdir = 0;
//  p2curdir = 0;
//}


void followmouse() {
  p1x = p1x + p1speed/(sqrt(sq(mouseX-p1x)+sq(mouseY-p1y)))*(mouseX-p1x);
  p1y = p1y + p1speed/(sqrt(sq(mouseX-p1x)+sq(mouseY-p1y)))*(mouseY-p1y);
}


float[] eat(float x1,float y1,float w1,float x2,float y2,float w2) {
  
  if (sq(x1-x2)+sq(y1-y2) < sq((w1+w2)/2)){
    if (w1 < w2) {
      w2=sqrt(sq(w1)+sq(w2));
      w1=0;
    }
    else {
      w1=sqrt(sq(w1)+sq(w2));
      w2=0;
    }
  }
  
  float[] res = {x1,y1,w1,x2,y2,w2};
  return res;
}


float[] eatghost(float gx,float gy,float gw,float px,float py,float pw) {
  float iseaten = 0;
  if (gw > 0 && sq(gx-px)+sq(gy-py) < sq((gw+pw)/2)){
    if (gw < pw) {
      pw=sqrt(sq(gw)+sq(pw));
      gw=0;
      iseaten = 1;
    }
    else {
      gw=sqrt(sq(gw)-sq(pw));
      pw=0;
    }
  }
  
  float[] res = {gx,gy,gw,px,py,pw,iseaten};
  return res;
}


float[] eateachother(float p1x,float p1y,float p1w, float p2x,float p2y,float p2w) {
  
  if (sq(p1x-p2x)+sq(p1y-p2y) < sq((p1w+p2w)/2)){
    if (p1w > p2w) {
      p1w=sqrt(sq(p1w)+sq(p2w));
      p2w=0;
    }
    else {
      p2w=sqrt(sq(p1w)+sq(p2w));
      p1w=0;
    }
  }
  
  float[] res = {p1x,p1y,p1w,p2x,p2y,p2w};
  return res;
}


void gameOver () {
  if (p1belly == 0 && p2belly == 0){
    textSize(90);
    text("Game Over", p1x-50, p1y-50);
    battlebgm.close();
    eatbgm.close();
    gameoverbgm.play();
    // gamemode = 0;
  }
  int sum = 0;
  for (int i = 0; i < ghost.length; i++){
    sum += ghost[i];
  }
  
  if (sum == 0 && !assemble && (p1belly==0 || p2belly==0)) {
    textSize(90);
    text("Win !", p1x-50, p1y-50);
    battlebgm.close();
    eatbgm.close();
    winbgm.play();
  }
  
  if (sum == 0 && assemble) {
    textSize(90);
    text("Win !", p1x-50, p1y-50);
    // gamemode = 0;
  }
}


boolean overButton(float x, float y, float wid, float hei) {
  if (mouseX >= x && mouseX <= x + wid &&
      mouseY >= y && mouseY <= y + hei) {
    return true;      
  }
  else {
    return false; 
  }
}


float[] drawtriangle(float x, float y, float degree, float d){
  float[] res = new float[6];

  res[0] = x + d*sin(radians(degree));
  res[1] = y - d*cos(radians(degree));
  
  res[2] = x + d*cos(radians(degree + 30));
  res[3] = y + d*sin(radians(degree + 30));
  
  res[4] = x - d*cos(radians(30 - degree));
  res[5] = y + d*sin(radians(30 - degree));
  
  return res;
}