import { useState, useEffect } from "react";
import { View, Text, ScrollView, TouchableOpacity, Image } from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Fingerprint } from "lucide-react-native";

import { useCapsule, useOpenCapsule } from "@/hooks/use-capsules";
import { UnlockAnimation } from "@/components/animations/unlock-animation";
import { Button } from "@/components/ui/button";
import { RichTextView } from "@/components/shared/rich-text-view";
import { parseBlocks } from "@/lib/rich-text";
import { BiometricService } from "@/services/biometric-service";
import { formatDate } from "@/lib/date";
import { colors } from "@/constants/colors";

export default function UnlockScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const insets = useSafeAreaInsets();
  const { data: capsule, isLoading } = useCapsule(id!);
  const openCapsule = useOpenCapsule();

  const [animating, setAnimating] = useState(true);
  const [bioPassed, setBioPassed] = useState(false);
  const [bioChecking, setBioChecking] = useState(false);
  const [bioFailed, setBioFailed] = useState(false);
  const [openedAt] = useState(() => Date.now());

  const requiresBiometric = !!capsule?.requireBiometric;

  const runBiometricCheck = async () => {
    setBioChecking(true);
    setBioFailed(false);
    const ok = await BiometricService.authenticate();
    setBioChecking(false);
    if (ok) {
      setBioPassed(true);
    } else {
      setBioFailed(true);
    }
  };

  useEffect(() => {
    if (!requiresBiometric || bioPassed) return;
    const timer = setTimeout(() => {
      runBiometricCheck();
    }, 0);
    return () => clearTimeout(timer);
  }, [requiresBiometric, bioPassed]);

  if (isLoading || !capsule) {
    return (
      <View className="flex-1 items-center justify-center bg-cream dark:bg-brown">
        <Text className="font-sans text-muted-foreground">Loading...</Text>
      </View>
    );
  }

  if (requiresBiometric && !bioPassed) {
    return (
      <View className="flex-1 items-center justify-center bg-brown px-6">
        <View className="bg-sage/20 rounded-full p-6 mb-6">
          <Fingerprint size={40} color={colors.sage} />
        </View>
        <Text className="font-heading text-2xl font-bold text-cream text-center mb-2">
          This capsule is protected
        </Text>
        <Text className="font-sans text-base text-border text-center mb-8">
          Verify your identity to open &ldquo;{capsule.title}&rdquo;
        </Text>
        <TouchableOpacity
          onPress={runBiometricCheck}
          disabled={bioChecking}
          className="bg-sage rounded-full w-20 h-20 items-center justify-center mb-4"
        >
          <Fingerprint size={36} color={colors.cream} />
        </TouchableOpacity>
        {bioFailed && (
          <Text className="font-sans text-sm text-destructive mb-4 text-center">
            Authentication failed. Tap to try again.
          </Text>
        )}
        <Button
          label="Cancel"
          variant="ghost"
          onPress={() => router.back()}
        />
      </View>
    );
  }

  const handleAnimationComplete = async () => {
    setAnimating(false);
    await openCapsule.mutateAsync(capsule.id);
  };

  if (animating) {
    return (
      <UnlockAnimation
        createdAt={capsule.createdAt}
        openedAt={openedAt}
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

        <View className="bg-muted dark:bg-brown-light rounded-2xl px-4 py-3 flex-row gap-6 mb-8">
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
              {formatDate(openedAt)}
            </Text>
          </View>
        </View>

        <View className="bg-card dark:bg-brown-card rounded-3xl p-6 w-full border border-border/50 dark:border-brown-light/50 mb-8">
          <RichTextView blocks={parseBlocks(capsule.content)} />
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
