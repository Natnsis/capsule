import { useState } from "react";
import {
  View,
  Text,
  TextInput,
  ScrollView,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  Alert,
  useColorScheme,
} from "react-native";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import {
  X,
  Calendar,
  Image as ImageIcon,
  Plus,
  Tag,
  Type,
  MessageSquare,
  Clock,
  Sparkles,
} from "lucide-react-native";
import * as ImagePicker from "expo-image-picker";

import { Button } from "@/components/ui/button";
import { PRESET_DATES } from "@/constants/dates";
import { formatDate } from "@/lib/date";
import { generateId } from "@/lib/id";

export default function CreateCapsuleScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [selectedDate, setSelectedDate] = useState<number | null>(null);
  const [customDate, setCustomDate] = useState<Date | null>(null);
  const [tags, setTags] = useState<string[]>([]);
  const [tagInput, setTagInput] = useState("");
  const [imageUris, setImageUris] = useState<string[]>([]);

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

  const handleAddTag = () => {
    const trimmed = tagInput.trim();
    if (trimmed && !tags.includes(trimmed)) {
      setTags((prev) => [...prev, trimmed]);
      setTagInput("");
    }
  };

  const handlePreview = () => {
    if (!title.trim()) {
      Alert.alert("Title Required", "Please give your capsule a title.");
      return;
    }
    if (!content.trim()) {
      Alert.alert("Message Required", "Write a message to your future self.");
      return;
    }
    if (!selectedDate && !customDate) {
      Alert.alert("Date Required", "Select when this capsule should open.");
      return;
    }

    router.push({
      pathname: "/create/preview",
      params: {
        id: generateId(),
        title: title.trim(),
        content: content.trim(),
        openAt: (selectedDate || customDate!.getTime()).toString(),
        tags: JSON.stringify(tags),
        imageUris: JSON.stringify(imageUris),
      },
    });
  };

  const openAtDate = selectedDate || customDate?.getTime();

  return (
    <KeyboardAvoidingView
      className="flex-1 bg-[#F2EFEA] dark:bg-[#41393C]"
      behavior={Platform.OS === "ios" ? "padding" : "height"}
    >
      {/* Header */}
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

        {/* Progress indicator */}
        <View className="flex-row gap-1.5 px-4 pb-4">
          {[0, 1, 2, 3].map((step) => (
            <View
              key={step}
              className="flex-1 h-1 rounded-full bg-sage/30"
            >
              <View
                className={`h-full rounded-full bg-sage ${
                  step === 0
                    ? "w-full"
                    : step === 1 && (title.trim() || content.trim())
                      ? "w-full"
                      : step === 2 && (title.trim() && content.trim())
                        ? "w-full"
                        : step === 3 && (title.trim() && content.trim() && openAtDate)
                          ? "w-full"
                          : "w-0"
                }`}
              />
            </View>
          ))}
        </View>
      </View>

      <ScrollView className="flex-1 px-4" keyboardShouldPersistTaps="handled">
        {/* Title */}
        <View className="mb-6">
          <View className="flex-row items-center gap-2 mb-2">
            <Type size={16} color="#82B090" />
            <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider">
              Title
            </Text>
          </View>
          <View className="bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-2xl px-4 py-1">
            <TextInput
              className="font-heading text-xl font-semibold text-[#41393C] dark:text-[#F2EFEA] py-3"
              placeholder="What do you want to call this capsule?"
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
          <View className="bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-2xl px-4 py-1">
            <TextInput
              className="font-sans text-base text-[#41393C] dark:text-[#F2EFEA] py-3 min-h-[140px]"
              placeholder="Write a message to your future self..."
              placeholderTextColor="#7A6E71"
              value={content}
              onChangeText={setContent}
              multiline
              textAlignVertical="top"
            />
          </View>
        </View>

        {/* Open date */}
        <View className="mb-6">
          <View className="flex-row items-center gap-2 mb-2">
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
                  onPress={() => {
                    setSelectedDate(preset.value);
                    setCustomDate(null);
                  }}
                  className={`rounded-full px-4 py-2 ${
                    selected ? "bg-sage" : "bg-[#E4E0DA] dark:bg-[#5E4F53]"
                  }`}
                >
                  <Text
                    className={`font-sans text-sm font-medium ${
                      selected ? "text-[#F2EFEA]" : "text-[#41393C] dark:text-[#F2EFEA]"
                    }`}
                  >
                    {preset.label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
          {openAtDate && (
            <View className="bg-sage/10 rounded-2xl px-4 py-3 flex-row items-center">
              <Calendar size={18} color="#82B090" />
              <Text className="font-sans text-base text-sage ml-3 font-medium">
                Opens {formatDate(openAtDate)}
              </Text>
            </View>
          )}
        </View>

        {/* Tags */}
        <View className="mb-6">
          <View className="flex-row items-center gap-2 mb-2">
            <Tag size={16} color="#82B090" />
            <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider">
              Tags
            </Text>
          </View>
          <View className="flex-row items-center gap-2 mb-2">
            <View className="flex-1 bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-full px-4 py-1">
              <TextInput
                className="font-sans text-sm text-[#41393C] dark:text-[#F2EFEA] py-2"
                placeholder="Add a tag..."
                placeholderTextColor="#7A6E71"
                value={tagInput}
                onChangeText={setTagInput}
                onSubmitEditing={handleAddTag}
              />
            </View>
            <TouchableOpacity
              onPress={handleAddTag}
              className="bg-sage rounded-full w-10 h-10 items-center justify-center"
            >
              <Plus size={18} color="#F2EFEA" />
            </TouchableOpacity>
          </View>
          {tags.length > 0 && (
            <View className="flex-row flex-wrap gap-2">
              {tags.map((tag) => (
                <TouchableOpacity
                  key={tag}
                  onPress={() => setTags((prev) => prev.filter((t) => t !== tag))}
                >
                  <View className="bg-sage/20 rounded-full px-3 py-1.5 flex-row items-center gap-1.5">
                    <Text className="font-sans text-sm text-sage">{tag}</Text>
                    <X size={12} color="#82B090" />
                  </View>
                </TouchableOpacity>
              ))}
            </View>
          )}
        </View>

        {/* Photos */}
        <View className="mb-6">
          <View className="flex-row items-center gap-2 mb-2">
            <ImageIcon size={16} color="#82B090" />
            <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider">
              Photos
            </Text>
          </View>
          <TouchableOpacity
            onPress={handlePickImages}
            className="bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-2xl px-4 py-8 items-center justify-center"
          >
            <View className="bg-sage/20 rounded-full p-3 mb-2">
              <ImageIcon size={24} color="#82B090" />
            </View>
            <Text className="font-sans text-sm text-[#7A6E71]">
              Tap to add photos
            </Text>
            {imageUris.length > 0 && (
              <Text className="font-sans text-sm text-sage mt-1">
                {imageUris.length} photo{imageUris.length > 1 ? "s" : ""} selected
              </Text>
            )}
          </TouchableOpacity>
        </View>

        {/* Submit */}
        <View className="py-6">
          <TouchableOpacity
            onPress={handlePreview}
            className="bg-sage rounded-full py-4 flex-row items-center justify-center gap-2 shadow-lg shadow-sage/30"
          >
            <Sparkles size={20} color="#F2EFEA" />
            <Text className="font-heading text-lg font-semibold text-[#F2EFEA]">
              Preview Capsule
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
