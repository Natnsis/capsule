import { useState, useEffect, useRef } from "react";
import {
  View,
  Text,
  TextInput,
  ScrollView,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  Image,
  Animated,
} from "react-native";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useColorScheme } from "nativewind";
import {
  X,
  Type,
  Calendar,
  Image as ImageIcon,
  MessageSquare,
  Clock,
  Sparkles,
} from "lucide-react-native";
import * as ImagePicker from "expo-image-picker";

import { PRESET_DATES } from "@/constants/dates";
import { formatDate } from "@/lib/date";
import { generateId } from "@/lib/id";
import { Toast } from "@/components/shared/toast";
import { CalendarPicker } from "@/components/shared/calendar-picker";

export default function CreateCapsuleScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { colorScheme } = useColorScheme();
  const isDark = colorScheme === "dark";

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [selectedDate, setSelectedDate] = useState<number | null>(null);
  const [imageUris, setImageUris] = useState<string[]>([]);
  const [toast, setToast] = useState<{ message: string; variant: "success" | "error" | "info" } | null>(null);
  const [showCalendar, setShowCalendar] = useState(false);

  // Fade-in on mount to avoid white flash
  const fadeAnim = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    Animated.timing(fadeAnim, { toValue: 1, duration: 200, useNativeDriver: true }).start();
  }, []);

  const handlePickImages = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ["images"],
      allowsMultipleSelection: true,
      quality: 0.8,
    });

    if (!result.canceled) {
      setImageUris((prev) => [
        ...prev,
        ...result.assets.map((a: { uri: string }) => a.uri),
      ]);
    }
  };

  const removeImage = (uri: string) => {
    setImageUris((prev) => prev.filter((u) => u !== uri));
  };

  const handleSeal = () => {
    if (!title.trim()) {
      setToast({ message: "Please give your capsule a title", variant: "error" });
      return;
    }
    if (!content.trim()) {
      setToast({ message: "Write a message to your future self", variant: "error" });
      return;
    }
    if (!selectedDate) {
      setToast({ message: "Select when this capsule should open", variant: "error" });
      return;
    }

    router.push({
      pathname: "/create/preview",
      params: {
        id: generateId(),
        title: title.trim(),
        content: content.trim(),
        openAt: selectedDate.toString(),
        imageUris: JSON.stringify(imageUris),
        tags: JSON.stringify([]),
      },
    });
  };

  return (
    <KeyboardAvoidingView
      className="flex-1 bg-[#F2EFEA] dark:bg-[#41393C]"
      behavior={Platform.OS === "ios" ? "padding" : "height"}
    >
      <Toast
        message={toast?.message ?? ""}
        variant={toast?.variant ?? "info"}
        visible={!!toast}
        onHide={() => setToast(null)}
      />

      <Animated.View style={{ opacity: fadeAnim, flex: 1 }}>
        <View style={{ paddingTop: insets.top }}>
          <View className="flex-row items-center justify-between px-4 py-3">
            <TouchableOpacity
              onPress={() => router.back()}
              className="w-9 h-9 rounded-full bg-[#E4E0DA] dark:bg-[#5E4F53] items-center justify-center"
            >
              <X size={18} color={isDark ? "#F2EFEA" : "#41393C"} />
            </TouchableOpacity>
            <Text className="font-heading text-lg font-semibold text-[#41393C] dark:text-[#F2EFEA]">
              New Capsule
            </Text>
            <View style={{ width: 36 }} />
          </View>
        </View>

        <ScrollView className="flex-1 px-4" keyboardShouldPersistTaps="handled">
          {/* Title */}
          <View className="mb-6 mt-2">
            <View className="flex-row items-center gap-2 mb-2">
              <Type size={16} color="#82B090" />
              <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider">
                Title
              </Text>
            </View>
            <View className="bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-2xl px-5 py-1">
              <TextInput
                className="font-sans text-lg text-[#41393C] dark:text-[#F2EFEA] py-3"
                placeholder="Name your capsule"
                placeholderTextColor="#7A6E71"
                value={title}
                onChangeText={setTitle}
              />
            </View>
          </View>

          {/* Message */}
          <View className="mb-6">
            <View className="flex-row items-center gap-2 mb-2">
              <MessageSquare size={16} color="#82B090" />
              <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider">
                Message
              </Text>
            </View>
            <View className="bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-2xl px-5 py-2">
              <TextInput
                className="font-sans text-base text-[#41393C] dark:text-[#F2EFEA] py-2 leading-6"
                placeholder="Write a letter to your future self"
                placeholderTextColor="#7A6E71"
                value={content}
                onChangeText={setContent}
                multiline
                textAlignVertical="top"
                style={{ minHeight: 280, maxHeight: 500 }}
              />
            </View>
          </View>

          {/* Open date */}
          <View className="mb-6">
            <View className="flex-row items-center gap-2 mb-3">
              <Clock size={16} color="#82B090" />
              <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider">
                Opens On
              </Text>
            </View>
            <View className="flex-row flex-wrap gap-2 mb-3">
              {PRESET_DATES.map((preset) => {
                const selected = selectedDate === preset.value;
                return (
                  <TouchableOpacity
                    key={preset.label}
                    onPress={() => setSelectedDate(preset.value)}
                    className={`rounded-full px-5 py-2.5 ${
                      selected ? "bg-sage" : "bg-[#E4E0DA] dark:bg-[#5E4F53]"
                    }`}
                  >
                    <Text
                      className={`font-sans text-sm font-semibold ${
                        selected ? "text-[#F2EFEA]" : "text-[#41393C] dark:text-[#F2EFEA]"
                      }`}
                    >
                      {preset.label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
              <TouchableOpacity
                onPress={() => setShowCalendar(true)}
                className={`rounded-full px-5 py-2.5 ${
                  showCalendar ? "bg-sage" : "bg-[#E4E0DA] dark:bg-[#5E4F53]"
                }`}
              >
                <Text
                  className={`font-sans text-sm font-semibold ${
                    showCalendar ? "text-[#F2EFEA]" : "text-[#41393C] dark:text-[#F2EFEA]"
                  }`}
                >
                  Custom
                </Text>
              </TouchableOpacity>
            </View>
            {selectedDate && (
              <View className="bg-sage/10 rounded-2xl px-5 py-3.5 flex-row items-center">
                <Calendar size={18} color="#82B090" />
                <Text className="font-sans text-base text-sage ml-3 font-semibold">
                  Opens {formatDate(selectedDate)}
                </Text>
              </View>
            )}
          </View>

          {/* Photos */}
          <View className="mb-6">
            <View className="flex-row items-center gap-2 mb-3">
              <ImageIcon size={16} color="#82B090" />
              <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider">
                Photos
              </Text>
            </View>

            {imageUris.length > 0 && (
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                className="mb-3 -mx-4 px-4"
              >
                <View className="flex-row gap-2">
                  {imageUris.map((uri, idx) => (
                    <View key={idx} className="relative mt-2 mr-2">
                      <Image source={{ uri }} className="w-24 h-24 rounded-2xl" />
                      <TouchableOpacity
                        onPress={() => removeImage(uri)}
                        className="absolute -top-2.5 -right-2.5 w-6 h-6 rounded-full bg-red-500 items-center justify-center"
                        style={{ elevation: 4, shadowColor: "#000", shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.25, shadowRadius: 3 }}
                      >
                        <X size={12} color="white" />
                      </TouchableOpacity>
                    </View>
                  ))}
                </View>
              </ScrollView>
            )}

            <TouchableOpacity
              onPress={handlePickImages}
              className="bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-2xl px-4 py-8 items-center justify-center"
            >
              <View className="bg-sage/20 rounded-full p-3 mb-2">
                <ImageIcon size={24} color="#82B090" />
              </View>
              <Text className="font-sans text-sm text-[#7A6E71]">
                {imageUris.length > 0
                  ? `${imageUris.length} photo${imageUris.length > 1 ? "s" : ""} selected`
                  : "Tap to add photos"}
              </Text>
            </TouchableOpacity>
          </View>

          {/* Submit */}
          <View className="py-6">
            <TouchableOpacity
              onPress={handleSeal}
              className="bg-sage rounded-full py-4 flex-row items-center justify-center gap-2 shadow-lg shadow-sage/30"
            >
              <Sparkles size={20} color="#F2EFEA" />
              <Text className="font-heading text-lg font-semibold text-[#F2EFEA]">
                Preview Capsule
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </Animated.View>

      <CalendarPicker
        visible={showCalendar}
        currentValue={selectedDate}
        onSelect={(ts) => {
          setSelectedDate(ts);
          setShowCalendar(false);
        }}
        onClose={() => setShowCalendar(false)}
      />
    </KeyboardAvoidingView>
  );
}
