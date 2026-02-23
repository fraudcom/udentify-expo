import { Text } from "@/components/ThemedText";
import { useThemedColors } from "@/components/useThemedColors";
import { useVoice } from "@/contexts/VoiceContext";
import { ScrollView, StyleSheet, View, Pressable } from "react-native";

export default function Settings() {
  const colors = useThemedColors();
  const { voices, selectedVoice, setSelectedVoice, speak, stop } = useVoice();

  const handleVoiceSelect = (voice: typeof voices[0] | null) => {
    stop();
    setSelectedVoice(voice);
    speak("Expo Modules are the best", voice);
  };

  return (
    <ScrollView
      contentInsetAdjustmentBehavior="automatic"
      style={styles.container}
    >
      <View style={styles.content}>
        <Text size="header" style={styles.title}>
          Settings
        </Text>

        <View style={styles.section}>
          <Text size="caption" style={styles.sectionTitle}>
            OCR MODULE STATUS
          </Text>
          <View style={styles.row}>
            <Text style={styles.label}>OCR Available</Text>
            <Text style={styles.value}>Yes</Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.label}>Status</Text>
            <Text style={styles.value}>Ready</Text>
          </View>
        </View>

        <View style={styles.section}>
          <Text size="caption" style={styles.sectionTitle}>
            VOICE SELECTION
          </Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            <View style={styles.voiceList}>
              <Pressable
                style={({ pressed }) => [
                  styles.voiceItem,
                  {
                    borderColor: colors.border,
                    backgroundColor: !selectedVoice
                      ? colors.selected
                      : "transparent",
                  },
                  pressed && styles.pressed,
                ]}
                onPress={() => handleVoiceSelect(null)}
              >
                <Text style={styles.voiceText}>Default</Text>
              </Pressable>
              {voices.slice(0, 10).map((voice) => (
                <Pressable
                  key={voice.identifier}
                  style={({ pressed }) => [
                    styles.voiceItem,
                    {
                      borderColor: colors.border,
                      backgroundColor:
                        selectedVoice?.identifier === voice.identifier
                          ? colors.selected
                          : "transparent",
                    },
                    pressed && styles.pressed,
                  ]}
                  onPress={() => handleVoiceSelect(voice)}
                >
                  <Text style={styles.voiceText}>{voice.name}</Text>
                  <Text size="caption" style={styles.voiceLanguage}>
                    {voice.language}
                  </Text>
                </Pressable>
              ))}
            </View>
          </ScrollView>
          <Text size="caption" style={styles.voiceHint}>
            {voices.length > 10 ? `Showing 10 of ${voices.length} voices` : `${voices.length} voices available`}
          </Text>
        </View>

        <View style={styles.banner}>
          <Text size="caption" style={styles.bannerText}>
            Powered by Udentify OCR SDK
          </Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    padding: 20,
  },
  title: {
    marginBottom: 32,
  },
  section: {
    marginBottom: 32,
  },
  sectionTitle: {
    opacity: 0.6,
    marginBottom: 16,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: "rgba(128, 128, 128, 0.2)",
  },
  label: {
    opacity: 0.8,
  },
  value: {
    fontWeight: "500",
  },
  voiceList: {
    flexDirection: "row",
    gap: 12,
  },
  voiceItem: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderWidth: 1,
    borderRadius: 8,
    minWidth: 120,
    alignItems: "center",
  },
  voiceText: {
    fontSize: 14,
    fontWeight: "500",
    marginBottom: 2,
  },
  voiceLanguage: {
    opacity: 0.6,
  },
  voiceHint: {
    opacity: 0.5,
    marginTop: 12,
  },
  pressed: {
    opacity: 0.7,
  },
  banner: {
    marginTop: 40,
    paddingVertical: 20,
    alignItems: "center",
  },
  bannerText: {
    opacity: 0.4,
    fontWeight: "bold",
  },
});
