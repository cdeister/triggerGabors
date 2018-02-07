#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define OLED_RESET 4
#define tSer Serial1
Adafruit_SSD1306 display(OLED_RESET);


#if (SSD1306_LCDHEIGHT != 32)
#error("Height incorrect, please fix Adafruit_SSD1306.h!");
#endif

char knownHeaders[] = {'t', 'o', 'c', 's', 'f', 't', 'v'};
int knownValues[] = {0, 0, 0, 0, 0, 0, 0};
int knownCount = 7;
int varRec = 0;
int useDisplay = 1;
int dispCounter = 0;


void setup()   {
  tSer.begin(9600);
  Serial.begin(9600);
  if (useDisplay) {
    // ** Initialize the i2c, by pulling the pin high (you can call the pull up).
    display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
    // initialize with the I2C addr 0x3C (for the 128x32)
    display.display();
    delay(100);
    updateDisp();
  }
}


void loop() {

  // look for variables on the hardware line
  int p = flagReceive(knownHeaders, knownValues);

  // Update the display periodically.
  if (dispCounter > 100) {
    dispCounter = 0;
    updateDisp();
  }

  // knownValues[7] is a block call.
  // The logic is to have python call for a block while it confirms variable changes.
  if (knownValues[6] == 1) {
    Serial.print('v');
    Serial.print(',');
    Serial.print(knownValues[0]);
    Serial.print(',');
    Serial.print(knownValues[1]);
    Serial.print(',');
    Serial.print(knownValues[2]);
    Serial.print(',');
    Serial.print(knownValues[3]);
    Serial.print(',');
    Serial.print(knownValues[4]);
    Serial.print(',');
    Serial.print(knownValues[5]);
    Serial.print(',');
    Serial.println(knownValues[6]);
    knownValues[6] = 0;
  }
  dispCounter++;
  delay(1);
}
// This function listens for things on the serial line
// It's a pile of mess, various globals etc. Will clean up later.

int flagReceive(char varAr[], int valAr[]) {
  static boolean recvInProgress = false;
  static byte ndx = 0;
  char endMarker = '>';
  char feedbackMarker = '<';
  char rc;
  int nVal;
  const byte numChars = 32;
  char writeChar[numChars];
  int newData = 0;
  int selectedVar = 0;

  while (tSer.available() > 0 && newData == 0) {
    rc = tSer.read();
    if (recvInProgress == false) {
      for ( int i = 0; i < knownCount; i++) {
        if (rc == varAr[i]) {
          selectedVar = i;
          recvInProgress = true;
        }
      }
    }

    else if (recvInProgress == true) {
      if (rc == endMarker ) {
        writeChar[ndx] = '\0'; // terminate the string
        recvInProgress = false;
        ndx = 0;
        newData = 1;

        nVal = int(String(writeChar).toInt());
        valAr[selectedVar] = nVal;

      }
      else if (rc == feedbackMarker) {
        writeChar[ndx] = '\0'; // terminate the string
        recvInProgress = false;
        ndx = 0;
        newData = 1;
        tSer.print("echo");
        tSer.print(',');
        tSer.print(selectedVar);
        tSer.print(',');
        tSer.print(valAr[selectedVar]);
        tSer.print(',');
        tSer.println('~');
      }

      else if (rc != feedbackMarker || rc != endMarker) {
        writeChar[ndx] = rc;
        ndx++;
        if (ndx >= numChars) {
          ndx = numChars - 1;
        }
      }
    }
  }
  return selectedVar; // tells us if a valid variable arrived.
}


void updateDisp() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0, 0);
  display.print("Trial: ");
  display.println(knownValues[0]);
  display.setCursor(0, 10);
  display.print("Orient: ");
  display.println(knownValues[1]);
  display.setCursor(0, 20);
  display.print("SFreq:");
  display.println(knownValues[2]);
  display.setCursor(65, 20);
  display.print("TFreq:");
  display.println(knownValues[3]);
  display.display();
}


