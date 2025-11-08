#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// WiFi
#define WIFI_SSID "TP-LINK_F800"
#define WIFI_PASSWORD "88668866@"

// Firebase
#define API_KEY "AIzaSyD_OqYTFuB8HWXjn2C5iYAOg-mZLQUs4p8"
#define DATABASE_URL "https://smart-944cb-default-rtdb.asia-southeast1.firebasedatabase.app/"

// Đối tượng Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Chân LED (nếu bạn dùng LED rời, chọn GPIO 2 hoặc 4)
#define LED_PIN 2  

int ledState = 0;

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);

  // Kết nối WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Đang kết nối WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\n✅ Đã kết nối WiFi!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  // Cấu hình Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Nếu Database public thì có thể bỏ phần auth này
  auth.user.email = "nghialio2310@gmail.com";
  auth.user.password = "190031";

  // Khởi tạo Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Ghi dữ liệu ban đầu
  if (Firebase.RTDB.setInt(&fbdo, "/esp32/ledState", ledState)) {
    Serial.println("Đã ghi giá trị ban đầu lên Firebase");
  } else {
    Serial.println("Lỗi khi ghi dữ liệu:");
    Serial.println(fbdo.errorReason());
  }
}

void loop() {
  // Đọc trạng thái LED từ Firebase
  if (Firebase.RTDB.getInt(&fbdo, "/esp32/ledState")) {
    ledState = fbdo.intData();
    Serial.print("Trạng thái LED từ Firebase: ");
    Serial.println(ledState);

    // Điều khiển LED thật
    digitalWrite(LED_PIN, ledState ? HIGH : LOW);
  } else {
    Serial.print("Lỗi khi đọc dữ liệu: ");
    Serial.println(fbdo.errorReason());
  }

  delay(2000);
}
