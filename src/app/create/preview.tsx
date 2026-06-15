import { useState } from "react";
import { View, Text, ScrollView, Image } from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { Button } from "@/components/ui/button";
import { StatusBadge } from "@/components/capsules/status-badge";
import { SealAnimation } from "@/components/animations/seal-animation";
import { formatDate } from "@/lib/date";
import { useCreateCapsule } from "@/hooks/use-capsules";
import type { CreateCapsuleInput } from "@/types/capsule";

export default function PreviewScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const params = useLocalSearchParams();
  const createCapsule = useCreateCapsule();

  const [sealing, setSealing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const title = params.title as string;
  const content = params.content as string;
  const openAt = parseInt(params.openAt as string, 10);
  const tags = JSON.parse((params.tags as string) || "[]") as string[];
  const imageUris = JSON.parse(
    (params.imageUris as string) || "[]"
  ) as string[];

  const handleSeal = async () => {
    setSealing(true);

    try {
      const input: CreateCapsuleInput = {
        title,
        content,
        openAt,
        tags,
        imageUris,
      };

      await createCapsule.mutateAsync(input);

      setSealing(false);
      router.replace("/(tabs)");
    } catch (err) {
      setSealing(false);
      setError("Failed to seal capsule. Please try again.");
    }
  };

  if (sealing) {
    return (
      <View className="flex-1 bg-cream dark:bg-brown">
        <SealAnimation onComplete={() => {}} />
      </View>
    );
  }

  return (
    <ScrollView
      className="flex-1 bg-cream dark:bg-brown"
      contentContainerStyle={{ paddingBottom: 40 }}
    >
      <View style={{ paddingTop: insets.top + 16 }} className="px-4">
        <Text className="font-heading text-2xl font-bold text-brown dark:text-cream mb-1">
          Preview
        </Text>
        <Text className="font-sans text-base text-muted-foreground mb-6">
          Review your capsule before sealing it
        </Text>

        <View className="bg-cream dark:bg-[#4E4449] rounded-2xl p-6 border border-border/50 mb-6">
          <View className="flex-row items-start justify-between mb-4">
            <Text className="font-heading text-2xl font-bold text-brown dark:text-cream flex-1 mr-2">
              {title}
            </Text>
            <StatusBadge status="sealed" />
          </View>

          <Text className="font-sans text-base text-brown dark:text-cream leading-7 mb-6">
            {content}
          </Text>

          {imageUris.length > 0 && (
            <View className="flex-row flex-wrap gap-2 mb-4">
              {imageUris.map((uri, idx) => (
                <Image
                  key={idx}
                  source={{ uri }}
                  className="w-20 h-20 rounded-xl"
                />
              ))}
            </View>
          )}

          {tags.length > 0 && (
            <View className="flex-row flex-wrap gap-2 mb-4">
              {tags.map((tag) => (
                <View key={tag} className="bg-sage/20 rounded-full px-3 py-1">
                  <Text className="font-sans text-sm text-sage">{tag}</Text>
                </View>
              ))}
            </View>
          )}

          <View className="pt-4 border-t border-border/50 gap-2">
            <View className="flex-row items-center justify-between">
              <Text className="font-sans text-sm text-muted-foreground">
                Created
              </Text>
              <Text className="font-sans text-sm text-brown dark:text-cream font-medium">
                {formatDate(Date.now())}
              </Text>
            </View>
            <View className="flex-row items-center justify-between">
              <Text className="font-sans text-sm text-muted-foreground">
                Opens
              </Text>
              <Text className="font-sans text-sm text-sage font-semibold">
                {formatDate(openAt)}
              </Text>
            </View>
          </View>
        </View>

        {error && (
          <Text className="font-sans text-sm text-red-500 text-center mb-4">
            {error}
          </Text>
        )}

        <Button
          label="Seal Capsule"
          size="lg"
          onPress={handleSeal}
          loading={createCapsule.isPending}
          className="w-full mb-4"
        />

        <Button
          label="Go Back"
          variant="ghost"
          size="md"
          onPress={() => router.back()}
          className="w-full"
        />
      </View>
    </ScrollView>
  );
}
