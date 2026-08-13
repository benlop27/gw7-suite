  #include <Arduino.h>
  #include <BLEMIDI_Transport.h>
  #include <hardware/BLEMIDI_ESP32.h>
  #include <MIDI.h> 

  BLEMIDI_CREATE_INSTANCE("GW7", BLE_MIDI);
  MIDI_CREATE_INSTANCE(HardwareSerial, Serial2, Serial_MIDI);

  void setup() {
    // Iniciar el puerto de depuración por USB
    Serial.begin(115200);
    delay(1000); // Pequeña pausa para que la consola se inicialice
    Serial.println("======================================");
    Serial.println("  Bridge MIDI Bluetooth Iniciando...   ");
    Serial.println("======================================");
    
    BLE_MIDI.begin(MIDI_CHANNEL_OMNI);
    Serial_MIDI.begin(MIDI_CHANNEL_OMNI);

    BLE_MIDI.turnThruOff();
    Serial_MIDI.turnThruOff();
    
    Serial.println("Configuracion completa. Esperando conexion BLE...");
  }

  void loop() {
    if (BLE_MIDI.read()) {
      midi::MidiType type = BLE_MIDI.getType();
      byte channel = BLE_MIDI.getChannel();
      byte data1 = BLE_MIDI.getData1();
      byte data2 = BLE_MIDI.getData2();

      // --- IMPRESIÓN DE DEPURACIÓN ---
      Serial.print("BLE In: Tipo [");
      Serial.print(type, HEX); // Mostrar el tipo en Hexadecimal es estándar en MIDI
      Serial.print("] Canal: ");
      Serial.print(channel);
      Serial.print(" | Datos: ");
      Serial.print(data1);
      Serial.print(", ");
      Serial.print(data2);
      
      if (type == midi::SystemExclusive) {
        Serial.println(" -> (Reenviando SysEx por Serial2)");
        Serial_MIDI.sendSysEx(
          BLE_MIDI.getSysExArrayLength(), 
          BLE_MIDI.getSysExArray(), 
          true
        );
      } else {
        Serial.println(" -> (Reenviando por Serial2)");
        Serial_MIDI.send(type, data1, data2, channel);
      }
    }
    
    yield(); 
  }