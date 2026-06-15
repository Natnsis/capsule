import { useState } from "react";
import { View, Text, ScrollView, Image } from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import type { Capsule } from "@/types/capsule";
import { useCapsule, useOpenCapsule } from "@/hooks/use-capsules";
import { UnlockAnimation } from "@/components/animations/unlock-animation";
import { Button } from "@/components/ui/button";
import { formatDate } from "@/lib/date";

export default function UnlockScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const insets = useSafeAreaInsets();
  const { data: capsule, isLoading } = useCapsule(id!);
  const openCapsule = useOpenCapsule();

  const [animating, setAnimating] = useState(true);
  const [opened, setOpened] = useState(false);

  if (isLoading || !capsule) {
    return (
      <View className="flex-1 items-center justify-center bg-cream dark:bg-brown">
        <Text className="font-sans text-muted-foreground">Loading...</Text>
      </View>
    );
  }

  const handleAnimationComplete = async () => {
    setAnimating(false);
    setOpened(true);
    await openCapsule.mutateAsync(capsule.id);
  };

  if (animating) {
    return (
      <UnlockAnimation
        createdAt={capsule.createdAt}
        openedAt={Date.now()}
        onComplete={handleAnimationComplete}
      />
    );
  }

  return (
    <ScrollView
      className="flex-1 bg-cream dark:bg-brown"
      contentContainerStyle={{ paddingBottom: 40 }}
    >
      <View
        style={{ paddingTop: insets.top + 16 }}
        className="px-4 items-center"
      >
        <Text className="font-heading text-3xl font-bold text-brown dark:text-cream text-center mb-2">
          {capsule.title}
        </Text>

        <View className="bg-muted rounded-2xl px-4 py-3 flex-row gap-6 mb-8">
          <View className="items-center">
            <Text className="font-sans text-xs text-muted-foreground mb-1">
              Written
            </Text>
            <Text className="font-sans text-sm text-brown dark:text-cream font-medium">
              {formatDate(capsule.createdAt)}
            </Text>
          </View>
          <View className="w-px bg-border" />
          <View className="items-center">
            <Text className="font-sans text-xs text-muted-foreground mb-1">
              Opened
            </Text>
            <Text className="font-sans text-sm text-sage font-medium">
              {formatDate(Date.now())}
            </Text>
          </View>
        </View>

        <View className="bg-cream dark:bg-[#4E4449] rounded-3xl p-6 w-full border border-border/50 mb-8">
          <Text className="font-sans text-base text-brown dark:text-cream leading-7">
            {capsule.content}
          </Text>
        </View>

        {capsule.imageUris.length > 0 && (
          <View className="flex-row flex-wrap gap-2 mb-6 w-full">
            {capsule.imageUris.map((uri: string, idx: number) => (
              <Image
                key={idx}
                source={{ uri }}
                className="flex-1 min-h-[200px] rounded-2xl"
              />
            ))}
          </View>
        )}

        {capsule.tags.length > 0 && (
          <View className="flex-row flex-wrap gap-2 mb-8 w-full">
                {capsule.tags.map((tag: string) => (
              <View key={tag} className="bg-sage/20 rounded-full px-3 py-1">
                <Text className="font-sans text-sm text-sage">{tag}</Text>
              </View>
            ))}
          </View>
        )}

        <Button
          label="Return Home"
          variant="outline"
          size="lg"
          onPress={() => router.replace("/(tabs)")}
          className="w-full"
        />
      </View>
    </ScrollView>
  );
}
