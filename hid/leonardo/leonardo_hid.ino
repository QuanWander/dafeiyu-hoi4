// DaFeiYu HOI4 HID bridge for Arduino Leonardo / Micro / Pro Micro
// Board must support native USB HID (ATmega32u4).
#include <Keyboard.h>

void openConsole() {
  Keyboard.press(KEY_LEFT_SHIFT);
  Keyboard.press('`');
  delay(80);
  Keyboard.releaseAll();
  delay(350);
}

void typeCommand() {
  Keyboard.print("run dfy_orders.txt");
  delay(120);
  Keyboard.press(KEY_RETURN);
  delay(80);
  Keyboard.releaseAll();
  delay(450);
}

void closeConsole() {
  Keyboard.press('`');
  delay(80);
  Keyboard.releaseAll();
}

void setup() {
  Serial.begin(115200);
  Keyboard.begin();
  delay(800);
}

void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    cmd.toUpperCase();
    if (cmd == "PING") {
      Serial.println("PONG");
    } else if (cmd == "RUN") {
      openConsole();
      typeCommand();
      closeConsole();
      Serial.println("OK");
    }
  }
}
