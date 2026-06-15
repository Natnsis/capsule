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
} from "react-native";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { X, Calendar, Image as ImageIcon, Plus } from "lucide-react-native";
import * as ImagePicker from "expo-image-picker";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { PRESET_DATES } from "@/constants/dates";
import { formatDate } from "@/lib/date";
import { generateId } from "@/lib/id";

export default function CreateCapsuleScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();

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
      const uris = result.assets.map((a: { uri: string }) => a.uri);
      setImageUris((prev) => [...prev, ...uris]);
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
      Alert.alert("Message Required", "Please write a message for your future self.");
      return;
    }
    if (!selectedDate && !customDate) {
      Alert.alert("Date Required", "Please select when this capsule should open.");
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
      className="flex-1 bg-cream dark:bg-brown"
      behavior={Platform.OS === "ios" ? "padding" : "height"}
    >
      <View style={{ paddingTop: insets.top }}>
        <View className="flex-row items-center justify-between px-4 py-3">
          <TouchableOpacity onPress={() => router.back()}>
            <X size={24} className="text-brown dark:text-cream" />
          </TouchableOpacity>
          <Text className="font-heading text-lg font-semibold text-brown dark:text-cream">
            New Capsule
          </Text>
          <View style={{ width: 24 }} />
        </View>
      </View>

      <ScrollView className="flex-1 px-4" keyboardShouldPersistTaps="handled">
        <Text className="font-heading text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-2 mt-4">
          Title
        </Text>
        <TextInput
          className="bg-muted rounded-2xl px-4 py-3 font-sans text-brown dark:text-cream text-lg"
          placeholder="What do you want to call this capsule?"
          placeholderTextColor="#7A6E71"
          value={title}
          onChangeText={setTitle}
        />

        <Text className="font-heading text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-2 mt-6">
          Message
        </Text>
        <TextInput
          className="bg-muted rounded-2xl px-4 py-3 font-sans text-brown dark:text-cream text-base min-h-[160px]"
          placeholder="Write your message to future you..."
          placeholderTextColor="#7A6E71"
          value={content}
          onChangeText={setContent}
          multiline
          textAlignVertical="top"
        />

        <Text className="font-heading text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-2 mt-6">
          Opens On
        </Text>
        <View className="flex-row flex-wrap gap-2 mb-3">
          {PRESET_DATES.map((preset) => (
            <TouchableOpacity key={preset.label} onPress={() => { setSelectedDate(preset.value); setCustomDate(null); }}>
              <Badge
                variant={selectedDate === preset.value ? "active" : "outline"}
                label={preset.label}
              />
            </TouchableOpacity>
          ))}
        </View>

        {openAtDate && (
          <View className="bg-sage/10 rounded-2xl px-4 py-3 flex-row items-center mb-2">
            <Calendar size={18} color="#82B090" />
            <Text className="font-sans text-base text-sage ml-3 font-medium">
              Opens {formatDate(openAtDate)}
            </Text>
          </View>
        )}

        <Text className="font-heading text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-2 mt-6">
          Tags
        </Text>
        <View className="flex-row items-center gap-2 mb-2">
          <TextInput
            className="flex-1 bg-muted rounded-full px-4 py-2 font-sans text-brown dark:text-cream text-sm"
            placeholder="Add a tag..."
            placeholderTextColor="#7A6E71"
            value={tagInput}
            onChangeText={setTagInput}
            onSubmitEditing={handleAddTag}
          />
          <TouchableOpacity
            onPress={handleAddTag}
            className="bg-sage rounded-full w-9 h-9 items-center justify-center"
          >
            <Plus size={18} color="#F2EFEA" />
          </TouchableOpacity>
        </View>
        {tags.length > 0 && (
          <View className="flex-row flex-wrap gap-2 mb-2">
            {tags.map((tag) => (
              <TouchableOpacity
                key={tag}
                onPress={() => setTags((prev) => prev.filter((t) => t !== tag))}
              >
                <View className="bg-sage/20 rounded-full px-3 py-1 flex-row items-center gap-1">
                  <Text className="font-sans text-sm text-sage">{tag}</Text>
                  <X size={12} color="#82B090" />
                </View>
              </TouchableOpacity>
            ))}
          </View>
        )}

        <Text className="font-heading text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-2 mt-6">
          Photos
        </Text>
        <TouchableOpacity
          onPress={handlePickImages}
          className="bg-muted rounded-2xl px-4 py-6 items-center justify-center border-2 border-dashed border-border"
        >
          <ImageIcon size={32} color="#7A6E71" />
          <Text className="font-sans text-sm text-muted-foreground mt-2">
            Tap to add photos
          </Text>
        </TouchableOpacity>
        {imageUris.length > 0 && (
          <Text className="font-sans text-sm text-sage mt-1">
            {imageUris.length} photo{imageUris.length > 1 ? "s" : ""} selected
          </Text>
        )}

        <View className="py-8">
          <Button
            label="Preview Capsule"
            size="lg"
            onPress={handlePreview}
            className="w-full"
          />
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
