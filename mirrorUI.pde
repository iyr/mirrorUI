/* Magic Mirror UI
 * Daniel Strawn
 */

import java.util.Date;

PImage pilogo;
PFont woodWarriorLight;
PFont woodWarriorBold;
PFont woodWarriorRegular;
PFont Modulo;
PFont Grotesk;

float[] animationCurve = new float[60];
int clockX = 384;
int clockY = 40;
int[] currentTime = new int[3];

//cursors used for animation curve
int c = 0;
int cw = 0;

String[] months = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
String[] weekDays = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
int day = new Date().getDay() + 7;
//float yRatio;

//Set US cities for Weather API
String[] cities = {"Boulder", "Colorado Springs", "Denver", "Fort Collins"};
int curCity = 0;

//Set API key for Weather API
String apiKey = "";

JSONObject currentWeather;
JSONObject forecast;
String[] forecastDates = new String[5];
String curSky;
int curTemp;
int curHigh;
int curLow;
int numFetches = 0;
boolean drawForecast = false;

//true = Celsius
//false = Fahrenheit
boolean tU = false;

//display info
boolean drawInfo = false;

void setup() {
  noCursor();
  size(900, 1440);
  
  frameRate(60);
  fill(255);
  pilogo = loadImage("rpi.png");
  woodWarriorLight   = createFont("Woodwarrior-Light.otf", 32);
  woodWarriorBold    = createFont("Woodwarrior-Bold.otf", 32);
  woodWarriorRegular = createFont("Woodwarrior-Regular.otf", 32);
  Modulo             = createFont("Modulo.otf", 32);
  Grotesk            = createFont("Grotesk.otf", 32);

  currentTime[0] = hour();
  currentTime[1] = getMinuteTen();
  currentTime[2] = getMinuteOne();

  //generates a quadratic animation curve
  for (int i = 0; i < 60; i++) {
    animationCurve[i] = ((-15*(1-i)*(1+i))+1)*0.000287356;
    println(animationCurve[i]);
  }
  
  fetchWeather();
  imageMode(CENTER);
}

void draw() {
  background(0);
  textFont(Grotesk, 14);
  fill(128);
  text("C: change city", 5, height-100);
  text("T: change temperature unit", 8, height-85);
  text("W: display forecast", 9, height-70);
  
  textFont(woodWarriorLight, 32);
  fill(255);
  //Draw the name of the current city in the bottom left
  text(cities[curCity], 8, height-8);

  //update day every midnight
  if (hour() == 0) day = new Date().getDay() + 7;

  //automatically refresh weather data every 15 minutes.
  if ((minute())%15 == 0 && second() == 2) { 
    thread("fetchWeather");
    while (second() == 2);
    c = 59;
  }

  //Tenth minute rollover animation
  if (currentTime[1] != getMinuteTen()) {
    newMinuteTen();
  } else {
    if (minute() < 10) {
      text("0", clockX+40, clockY);
    } else {
      text(getMinuteTen(), clockX+40, clockY);
    }
  }

  //single minute rollover animation
  if (currentTime[2] != getMinuteOne()) {
    newMinuteOne();
  } else {
    text(getMinuteOne(), clockX+64, clockY);
  }
  
  //hour rollover animation
  if (currentTime[0] != hour()) {
    newHour();
  } else {
    if (hour() < 10) {
      text("0", clockX-24, clockY);
      text(hour(), clockX, clockY);
    } else {
      text(hour(), clockX-24, clockY);
    }
  }
  
  //reset cursor values
  if (cw == 59) {
    if(!drawForecast) cw = 0;
  } else {
    cw += 60/int(frameRate-1);
    cw = constrain(cw, 0, 59);
  }
  if (second()%2 == 1 || c == 0)
  {
    c = 59;
  } else {
    c -= 60/int(frameRate-1);
    c = constrain(c, 0, 59);
  }

  //Sketch may behave oddly on leap years
  switch(month()) {
  case 2:
    drawDays(28);
    break;
  case 4:
    drawDays(30);
    break;
  case 6:
    drawDays(30);
    break;
  case 9:
    drawDays(30);
    break;
  case 11:
    drawDays(30);
    break;
  default:
    drawDays(31);
    break;
  }
  drawSeconds();
  drawMonth();
  drawTemp();
  if (drawInfo){
    drawForecast = false;
    filter(BLUR, 2);
    drawInfo();
  }
  
  /*
  if(drawInfo){
    image(pilogo, width/2, height/2+450);
  } else {
    tint(24, 24, 24);
    image(pilogo, width/2, height/2);
    noTint();    
  }
  */
  
  if (drawForecast) drawForecast();
}

//draw clock seconds and punctuation because the given typeface does not support ':'
void drawSeconds(){
    textFont(woodWarriorLight, 32);
  text(second(), clockX+104, clockY);
  text(".", clockX+88, clockY);
  text(".", clockX+88, clockY-16);
  text(".", clockX+24, clockY);
  text(".", clockX+24, clockY-16);  
}

//Draws info page with attributions
void drawInfo(){
  translate(0, -200);
  textAlign(CENTER);
  textFont(Grotesk, 72);
  text("IoT  Mirror", width/2, 300);
  textSize(32);
  text("By", width/2, 350);
  text("Daniel  Strawn", width/2, 400);
  text("forwardsweep.net", width/2, 450);
    
  translate(0, 50);
  text("Written  in  Processing", width/2, 550);
  text("for   ATLS-2519", width/2, 600);
  text("processing.org", width/2, 650);
  
  text("Weather  API  used:", width/2, 750);
  text("OpenWeatherMap.org", width/2, 800);
  
  text("Typefaces  used:", width/2, 900);
  textFont(woodWarriorRegular, 24);
  text("WoodWarrior", width/2, 1050);
  textFont(Modulo, 40);
  text("Modulo", width/2, 950);
  textFont(Grotesk, 32);
  text("Grotesk", width/2, 1000);
  text("fontlibrary.org", width/2, 1100);
  
  text("raspberrypi.org", width/2, 1565);
  
  translate(0, 150);
  textAlign(BASELINE);
}

//Helper function barrowed verbatim from https://stackoverflow.com/questions/27475308/
//replaces all spaces in a string with "%20"
public String replace(String str) {
  return str.replaceAll(" ", "%20");
}

//updates forecast and current weather information
void fetchWeather() {
  //currentWeather = loadJSONObject("http://api.openweathermap.org/data/2.5/weather?q="+replace(cities[curCity])+",us&APPID="+apiKey);
  currentWeather = loadJSONObject("https://samples.openweathermap.org/data/2.5/weather?q=London,uk&appid=b6907d289e10d714a6e88b30761fae22");
  println("http://api.openweathermap.org/data/2.5/weather?q="+replace(cities[curCity])+"us&appid="+apiKey);
  //forecast = loadJSONObject("http://api.openweathermap.org/data/2.5/forecast?q="+replace(cities[curCity])+",us&mode=json&appid="+apiKey);
  forecast = loadJSONObject("https://samples.openweathermap.org/data/2.5/forecast?q=London,us&appid=b6907d289e10d714a6e88b30761fae22");
  curSky  = currentWeather.getJSONArray("weather").getJSONObject(0).getString("description");
  curTemp = tConv(currentWeather.getJSONObject("main").getFloat("temp"));
  curHigh = tConv(currentWeather.getJSONObject("main").getFloat("temp_max"));
  curLow  = tConv(currentWeather.getJSONObject("main").getFloat("temp_min"));
  numFetches++;
  for (int i = 0; i < 4; i++) {
    forecastDates[i] = forecast.getJSONArray("list").getJSONObject(i*8).getString("dt_txt");
  }
}

void drawForecast() {
  noFill();
  translate(0, map(animationCurve[int(map(cw, 0, 59, 59, 0))], 0, 15, 0, height));
  float colFac = map(cw, 0, 59, 0, 255);
  stroke(colFac);
  strokeWeight(5);
  rect(width/2, height/2, 350, 360, 50);
  //line(width/2, 350, width/2, height-350);

  int wSpeed;
  String wDir;
  for (int i = 0; i < 3; i++) {
    //line(constrain(i, 0, 1)*175+275, 270, constrain(i, 0, 1)*175+275, height-270);
    line(100, i*180+540, width-100, i*180+540);
  }
  for (int i = 0; i < 4; i++) {
    fill(colFac);
    stroke(colFac);
    line(width/2+50, i*180+440, width/2+50, i*180+540);
    translate(0, -8);
    textFont(woodWarriorRegular, 72);
    if (stringArray(forecastDates[i], 8) != 0) text(stringArray(forecastDates[i], 8), 135, i*180+520);
    text(stringArray(forecastDates[i], 9), 185, i*180+520);
    textAlign(CENTER);
    textFont(woodWarriorLight, 48);
    text(weekDays[day+1+i], 187.5, i*180+440);
    translate(4, 16);

    textAlign(LEFT);
    textFont(Grotesk, 36);
    text(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONArray("weather").getJSONObject(0).getString("main"), 285, i*180+400);
    textFont(Grotesk, 18);
    text(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONArray("weather").getJSONObject(0).getString("description"), 290, i*180+420);
    textFont(woodWarriorRegular, 18);
    wSpeed = msToMph(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("wind").getFloat("speed"));
    wDir  = degToDir(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("wind").getFloat("deg"));
    text(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("main").getInt("humidity"), 405, i*180+510);
    text(wSpeed, 290, i*180+465);
    textFont(Grotesk, 18);
    text(" mph - "+wDir, 312, i*180+465);
    text("Humidity", 290, i*180+505);
    textAlign(BASELINE);
    translate(-4, -8);

    translate(0, 90);
    strokeWeight(4);
    textFont(woodWarriorLight, 72);
    textAlign(RIGHT);
    if (tConv(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("main").getFloat("temp")) < 0) {
      rect(width/2 - 136, height-48, 18, 4);
    }
    if (abs(tConv(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("main").getFloat("temp"))) < 10) {
      text("0"+abs(tConv(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("main").getFloat("temp"))), width/2+200, i*180+400);
    } else {
      text(abs(tConv(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("main").getFloat("temp"))), width/2+200, i*180+400);
    }
    textSize(36);
    textAlign(LEFT);

    if (tU == false) {
      text("f", width/2+200, i*180+400);
    } else {    
      text("c", width/2+200, i*180+400);
    }
    noFill();
    ellipse(width/2+208, i*180+335, 12, 12);
    rect(width/2+264, i*180+362.5, 32, 0);
    textSize(24);
    if (tConv(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("main").getFloat("temp_max")) < 0) {
      rect(width/2+236, i*180+337.5, 3, 0);
    }
    if (tConv(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("main").getFloat("temp_min")) < 0) {
      rect(width/2+236, i*180+387.5, 3, 0);
    }
    text(abs(tConv(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("main").getFloat("temp_max"))), width/2+244, i*180+350);
    text(abs(tConv(forecast.getJSONArray("list").getJSONObject(i*8+4).getJSONObject("main").getFloat("temp_min"))), width/2+244, i*180+400);
    translate(0, -90);
    textAlign(BASELINE);
    stroke(255);
    fill(255);
  }
}

//helper function to convert meters/second to miles/hour
int msToMph(float ms) { 
  return round(ms*2.23694);
}

//helper function to convert wind heading in degrees to human-friendly directions
String degToDir(float degrees) {
  constrain(degrees, 0, 360);
  if (348.75 <= degrees || degrees < 11.24)   return "N";
  if (11.25 <= degrees && degrees < 33.74)    return "NNE";
  if (33.75 <= degrees && degrees < 56.24)    return "NE";
  if (56.25 <= degrees && degrees < 78.74)    return "ENE";
  if (78.75 <= degrees && degrees < 101.24)   return "E";
  if (101.25 <= degrees && degrees < 123.74)  return "ESE";
  if (123.75 <= degrees && degrees < 146.24)  return "SE";
  if (146.25 <= degrees && degrees < 168.74)  return "SSE";
  if (168.75 <= degrees && degrees < 191.24)  return "S";
  if (191.25 <= degrees && degrees < 213.74)  return "SSW";
  if (213.75 <= degrees && degrees < 236.24)  return "SW";
  if (236.25 <= degrees && degrees < 258.74)  return "WSW";
  if (258.75 <= degrees && degrees < 281.24)  return "W";
  if (281.25 <= degrees && degrees < 303.74)  return "WNW";
  if (303.75 <= degrees && degrees < 326.24)  return "NW";
  if (326.25 <= degrees && degrees < 348.74)  return "NNW";
  return Float.toString(degrees);
}


void drawTemp() {
  translate(width*0.375, 0);
  fill(255);
  stroke(255);
  strokeWeight(4);
  textFont(woodWarriorLight, 72);
  textAlign(RIGHT);
  if (curTemp < 0) {
    rect(width/2 - 136, height-48, 18, 4);
  }
  if (abs(curTemp) < 10) {
    text("0"+abs(curTemp), width/2, height-12);
  } else {
    text(abs(curTemp), width/2, height-12);
  }
  textFont(Grotesk, 24);
  text(curSky, width/2+100, height-100);
  textFont(woodWarriorLight, 36);
  textAlign(LEFT);

  if (tU == false) {
    text("f", width/2, height-12);
  } else {    
    text("c", width/2, height-12);
  }
  noFill();
  ellipse(width/2+8, height-76, 12, 12);
  rect(width/2 + 64, height-48, 32, 0);
  textSize(24);
  if (curHigh < 0) {
    rect(width/2+36, height-70, 3, 0);
  }
  if (curLow < 0) {
    rect(width/2+36, height-24, 3, 0);
  }
  text(abs(curHigh), width/2+44, height-58);
  text(abs(curLow), width/2+44, height-12);

  translate(-width*0.375, 0);
  textAlign(BASELINE);
}

void keyPressed() {
  switch(key) {
  case 't':
    tU = !tU;
    fetchWeather();
    background(0);
    if (drawForecast) drawForecast();
    break;

  case 'i':
    drawInfo = !drawInfo;
    break;

  case 'w':
    if(drawInfo) drawInfo = false;
    drawForecast = !drawForecast;
    cw = 0;
    break;

  case 'u':
    fetchWeather();
    break;

  case 'c':
    curCity = curCity == cities.length-1 ? 0 : curCity+1;
    fetchWeather();
    break;
  }
}

//helper function convert tempurate delivered from weather API from kelvin to *
int tConv(float kelvin) {
  if (tU == false) {
    return round(((9.0/5.0)*(kelvin-273.0))+32.0);
  } else {
    return round(kelvin - 273.15);
  }
}

//draws the current month on the right
void drawMonth() {
  textFont(Modulo, 32);
  //the following loop draws text vertically, but with each character oriented normally
  for (int i = 0; i < months[month() - 1].length(); i++) {
    text(stringArray(months[month() - 1], i), width - 32, (height/2 - 32*months[month() - 1].length()/2)+i*32);
  }
}

//helper function that treats strings as arrays of characters.
char stringArray(String toChar, int arrInd) {
  if (toChar == null) { 
    return '0';
  } else {  
    char[] arr = toChar.toCharArray();
    return arr[arrInd];
  }
}

//Draws the days of the month/week on the left
void drawDays(int numDays) {
  textFont(woodWarriorRegular, 14);
  rectMode(RADIUS);
  for (int i = 0; i < numDays; i++) {
    if (i+1 == day()) {
      fill(128, 255);
      text(weekDays[day - 1], 40, height/6+(i-1)*32);
      text(weekDays[day + 1], 40, height/6+(i+1)*32);
      fill(96, 255);
      text(weekDays[day - 2], 40, height/6+(i-2)*32);
      text(weekDays[day + 2], 40, height/6+(i+2)*32);
      fill(64, 255);
      text(weekDays[day - 3], 40, height/6+(i-3)*32);
      text(weekDays[day + 3], 40, height/6+(i+3)*32);
      fill(48, 255);
      text(weekDays[day - 4], 40, height/6+(i-4)*32);
      text(weekDays[day + 4], 40, height/6+(i+4)*32);
      fill(32, 255);
      text(weekDays[day - 5], 40, height/6+(i-5)*32);
      text(weekDays[day + 5], 40, height/6+(i+5)*32);      
      fill(255);
      rect(20, height/6-(height*8.0/1440)+i*32, 15, 15, 6);
      text(weekDays[day], 40, height/6+i*32);
      fill(0);
      text(i+1, 10, height/6+i*32);
    } else {
      fill(255);
      text(i+1, 10, height/6+i*32);
    }
  }
}

//hour rollover animation
void newHour() {
  translate(0, -4*animationCurve[c]);
  fill(c*4);
  if (hour() < 10) {
    text("0", clockX-24, clockY+60);
    text(currentTime[0], clockX, clockY+60);
  } else {
    text(currentTime[0], clockX-24, clockY+60);
  } 

  fill(255);
  if (hour() < 10) {
    text("0", clockX-24, clockY);
    text(hour(), clockX, clockY);
  } else {
    text(hour(), clockX-24, clockY);
  }
  translate(0, 4*animationCurve[c]);
  if (c == 0) {
    currentTime[0] = hour();
  }
}

//minute one rollover animation
void newMinuteOne() {
  translate(0, -4*animationCurve[c]);
  fill(c*4);
  text(currentTime[2], clockX+64, clockY+60); 

  fill(255);
  text(getMinuteOne(), clockX+64, clockY);
  translate(0, 4*animationCurve[c]);
  if (c == 0) {
    currentTime[2] = getMinuteOne();
  }
}

//tenth minute rollover animation
void newMinuteTen() {
  translate(0, -4*animationCurve[c]);
  fill(c*4);
  text(currentTime[1], clockX+40, clockY+60);

  fill(255);  
  text(minute(), clockX+40, clockY);
  translate(0, 4*animationCurve[c]);
  if (c == 0) {
    currentTime[1] = getMinuteTen();
  }
}

//helper functions to split minutes into ones and tens
//eg: getMinuteOne(23)=3, getMinuteTen(23)=2;
int getMinuteOne() {
  int[] minArr = new int[2];
  int curMin = minute();
  minArr[0] = curMin % 10;
  curMin /= 10;
  minArr[1] = curMin % 10;
  return minArr[0];
}

int getMinuteTen() {
  int[] minArr = new int[2];
  int curMin = minute();
  minArr[0] = curMin % 10;
  curMin /= 10;
  minArr[1] = curMin % 10;
  return minArr[1];
}
