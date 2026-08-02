import { useState } from "react";
import { View, Text, ScrollView, TouchableOpacity, Image } from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useColorScheme } from "nativewind";
import { differenceInDays } from "date-fns";
import { ArrowLeft, Trash2, Fingerprint } from "lucide-react-native";

import { useCapsule, useDeleteCapsule, useSealDraft } from "@/hooks/use-capsules";
import { StatusBadge } from "@/components/capsules/status-badge";
import { CountdownTimer } from "@/components/capsules/countdown-timer";
import { Button } from "@/components/ui/button";
import { Dialog } from "@/components/shared/dialog";
import { RichTextView } from "@/components/shared/rich-text-view";
import { parseBlocks } from "@/lib/rich-text";
import { formatDate } from "@/lib/date";
import { colors } from "@/constants/colors";

export default function CapsuleDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const insets = useSafeAreaInsets();
  const { colorScheme } = useColorScheme();
  const isDark = colorScheme === "dark";

  const { data: capsule, isLoading } = useCapsule(id!);
  const deleteCapsule = useDeleteCapsule();
  const sealDraft = useSealDraft();
  const [showSealDialog, setShowSealDialog] = useState(false);

  if (isLoading || !capsule) {
    return (
      <View className="flex-1 items-center justify-center bg-cream dark:bg-brown">
        <Text className="font-sans text-muted-foreground">Loading...</Text>
      </View>
    );
  }

  const isDraft = capsule.status === "draft";
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

  const handleSeal = () => {
    setShowSealDialog(false);
    sealDraft.mutate(capsule.id);
  };

  return (
    <ScrollView
      className="flex-1 bg-cream dark:bg-brown"
      contentContainerStyle={{ paddingBottom: 40 }}
    >
      <Dialog
        visible={showSealDialog}
        title="Seal this capsule?"
        message="Once sealed, its contents will be hidden until it opens. This can't be undone."
        onClose={() => setShowSealDialog(false)}
        actions={[
          { label: "Cancel", variant: "cancel", onPress: () => setShowSealDialog(false) },
          { label: "Seal", variant: "default", onPress: handleSeal },
        ]}
      />

      <View style={{ paddingTop: insets.top + 8 }} className="px-4">
        <View className="flex-row items-center justify-between mb-6">
          <TouchableOpacity onPress={() => router.back()}>
            <ArrowLeft size={24} color={isDark ? colors.cream : colors.brown} />
          </TouchableOpacity>
          <StatusBadge status={capsule.status} />
        </View>

        {isDraft && (
          <>
            <Text className="font-heading text-3xl font-bold text-brown dark:text-cream mb-2">
              {capsule.title}
            </Text>
            <Text className="font-sans text-sm text-muted-foreground mb-6">
              Written {formatDate(capsule.createdAt)} · not sealed yet
            </Text>

            <View className="mb-6">
              <RichTextView blocks={parseBlocks(capsule.content)} />
            </View>

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

            <Button
              label="Seal Capsule"
              size="lg"
              onPress={() => setShowSealDialog(true)}
              loading={sealDraft.isPending}
              className="w-full"
            />
          </>
        )}

        {isLocked && (
          <View className="bg-card dark:bg-brown-card rounded-3xl p-8 items-center mb-6 border border-border/50 dark:border-brown-light/50">
            <View className="bg-sage/20 rounded-full p-6 mb-5">
              <View className="w-16 h-16 rounded-full bg-sage items-center justify-center">
                <Text className="font-heading text-3xl text-cream font-bold">
                  {capsule.title.charAt(0).toUpperCase()}
                </Text>
              </View>
            </View>
            <Text className="font-heading text-2xl font-bold text-brown dark:text-cream text-center mb-1">
              {capsule.title}
            </Text>
            <Text className="font-sans text-sm text-muted-foreground text-center mb-6">
              Sealed until {formatDate(capsule.openAt)}
            </Text>
            <Text className="font-heading text-6xl font-bold text-secondary">
              {Math.max(0, differenceInDays(new Date(capsule.openAt), new Date()))}
            </Text>
            <Text className="font-sans text-sm text-muted-foreground uppercase tracking-wider mt-1 mb-3">
              days remaining
            </Text>
            <CountdownTimer openAt={capsule.openAt} size="sm" />
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
                  <Fingerprint size={14} color={colors.sage} />
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

            <View className="mb-6">
              <RichTextView blocks={parseBlocks(capsule.content)} />
            </View>

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
            <Trash2 size={16} color={colors.destructive} />
            <Text className="font-sans text-sm text-destructive">
              Delete Capsule
            </Text>
          </TouchableOpacity>
        )}
      </View>
    </ScrollView>
  );
}
