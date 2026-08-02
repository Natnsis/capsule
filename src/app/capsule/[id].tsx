import { View, Text, ScrollView, TouchableOpacity, Image } from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useColorScheme } from "nativewind";
import { ArrowLeft, Trash2, Fingerprint } from "lucide-react-native";

import { useCapsule, useDeleteCapsule } from "@/hooks/use-capsules";
import { StatusBadge } from "@/components/capsules/status-badge";
import { CountdownTimer } from "@/components/capsules/countdown-timer";
import { Button } from "@/components/ui/button";
import { formatDate } from "@/lib/date";

export default function CapsuleDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const insets = useSafeAreaInsets();
  const { colorScheme } = useColorScheme();
  const isDark = colorScheme === "dark";

  const { data: capsule, isLoading } = useCapsule(id!);
  const deleteCapsule = useDeleteCapsule();

  if (isLoading || !capsule) {
    return (
      <View className="flex-1 items-center justify-center bg-cream dark:bg-brown">
        <Text className="font-sans text-muted-foreground">Loading...</Text>
      </View>
    );
  }

  const isLocked = capsule.status === "sealed";
  const isReady = capsule.status === "ready";
  const isOpened = capsule.status === "opened";

  const handleDelete = () => {
    deleteCapsule.mutate(capsule.id, {
      onSuccess: () => router.back(),
    });
  };

  const handleOpen = () => {
    router.push(`/unlock/${capsule.id}`);
  };

  return (
    <ScrollView
      className="flex-1 bg-cream dark:bg-brown"
      contentContainerStyle={{ paddingBottom: 40 }}
    >
      <View style={{ paddingTop: insets.top + 8 }} className="px-4">
        <View className="flex-row items-center justify-between mb-6">
          <TouchableOpacity onPress={() => router.back()}>
            <ArrowLeft size={24} color={isDark ? "#EEF0F3" : "#181B21"} />
          </TouchableOpacity>
          <StatusBadge status={capsule.status} />
        </View>

        {isLocked && (
          <View className="bg-muted dark:bg-[#353C48] rounded-3xl p-8 items-center mb-6">
            <View className="bg-sage/20 rounded-full p-6 mb-4">
              <View className="w-16 h-16 rounded-full bg-sage items-center justify-center">
                <Text className="font-heading text-3xl text-cream font-bold">
                  {capsule.title.charAt(0).toUpperCase()}
                </Text>
              </View>
            </View>
            <Text className="font-heading text-2xl font-bold text-brown dark:text-cream text-center mb-2">
              {capsule.title}
            </Text>
            <Text className="font-sans text-base text-muted-foreground text-center mb-4">
              This capsule is sealed until {formatDate(capsule.openAt)}
            </Text>
            <CountdownTimer openAt={capsule.openAt} size="lg" />
          </View>
        )}

        {isReady && (
          <View className="items-center mb-8">
            <View className="bg-sage/10 rounded-3xl p-8 items-center w-full mb-4">
              <Text className="font-heading text-2xl font-bold text-brown dark:text-cream text-center mb-2">
                {capsule.title}
              </Text>
              <Text className="font-sans text-base text-muted-foreground text-center mb-4">
                Written on {formatDate(capsule.createdAt)}
              </Text>
              {capsule.requireBiometric && (
                <View className="flex-row items-center gap-2 bg-sage/10 rounded-full px-3 py-1.5">
                  <Fingerprint size={14} color="#3B608F" />
                  <Text className="font-sans text-xs text-sage font-semibold">
                    Protected with biometrics
                  </Text>
                </View>
              )}
            </View>
            <Button
              label="Open Capsule"
              size="lg"
              onPress={handleOpen}
              className="w-full"
            />
          </View>
        )}

        {isOpened && (
          <>
            <Text className="font-heading text-3xl font-bold text-brown dark:text-cream mb-2">
              {capsule.title}
            </Text>
            <Text className="font-sans text-sm text-muted-foreground mb-6">
              Written {formatDate(capsule.createdAt)} · Opened{" "}
              {capsule.openedAt ? formatDate(capsule.openedAt) : ""}
            </Text>

            <Text className="font-sans text-base text-brown dark:text-cream leading-7 mb-6">
              {capsule.content}
            </Text>

            {capsule.imageUris.length > 0 && (
              <View className="flex-row flex-wrap gap-2 mb-4">
                {capsule.imageUris.map((uri: string, idx: number) => (
                  <Image
                    key={idx}
                    source={{ uri }}
                    className="w-24 h-24 rounded-xl"
                  />
                ))}
              </View>
            )}

            {capsule.tags.length > 0 && (
              <View className="flex-row flex-wrap gap-2 mb-6">
                {capsule.tags.map((tag: string) => (
                  <View key={tag} className="bg-sage/20 rounded-full px-3 py-1">
                    <Text className="font-sans text-sm text-sage">{tag}</Text>
                  </View>
                ))}
              </View>
            )}
          </>
        )}

        {!isReady && (
          <TouchableOpacity
            onPress={handleDelete}
            className="flex-row items-center justify-center gap-2 py-4 mt-4"
          >
            <Trash2 size={16} color="#EF4444" />
            <Text className="font-sans text-sm text-red-500">
              Delete Capsule
            </Text>
          </TouchableOpacity>
        )}
      </View>
    </ScrollView>
  );
}
