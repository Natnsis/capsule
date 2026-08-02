import { useEffect } from "react";
import { View, Text } from "react-native";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withDelay,
  Easing,
  runOnJS,
  type EasingFunction,
} from "react-native-reanimated";
import { Sparkles } from "lucide-react-native";
import * as Haptics from "expo-haptics";
import { formatDate, timeElapsed } from "@/lib/date";

interface UnlockAnimationProps {
  createdAt: number;
  openedAt: number;
  onComplete: () => void;
}

export function UnlockAnimation({ createdAt, openedAt, onComplete }: UnlockAnimationProps) {
  const overlayOpacity = useSharedValue(1);
  const contentScale = useSharedValue(0.5);
  const contentOpacity = useSharedValue(0);
  const elapsedOpacity = useSharedValue(0);
  const elapsedTranslateY = useSharedValue(20);

  useEffect(() => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

    overlayOpacity.value = withTiming(0, { duration: 800, easing: Easing.inOut(Easing.quad) });

    contentOpacity.value = withDelay(
      600,
      withTiming(1, { duration: 600 })
    );

    contentScale.value = withDelay(
      600,
      withTiming(1, { duration: 600, easing: Easing.out(Easing.back(1.5) as unknown as EasingFunction) })
    );

    elapsedOpacity.value = withDelay(
      1200,
      withTiming(1, { duration: 400 })
    );

    elapsedTranslateY.value = withDelay(
      1200,
      withTiming(0, { duration: 400, easing: Easing.out(Easing.quad) })
    );

    const timer = setTimeout(() => {
      runOnJS(onComplete)();
    }, 3000);

    return () => clearTimeout(timer);
  }, []);

  const overlayStyle = useAnimatedStyle(() => ({
    opacity: overlayOpacity.value,
  }));

  const contentStyle = useAnimatedStyle(() => ({
    transform: [{ scale: contentScale.value }],
    opacity: contentOpacity.value,
  }));

  const elapsedStyle = useAnimatedStyle(() => ({
    opacity: elapsedOpacity.value,
    transform: [{ translateY: elapsedTranslateY.value }],
  }));

  const elapsed = timeElapsed(createdAt, openedAt);

  return (
    <View className="flex-1 items-center justify-center bg-background">
      <Animated.View
        style={overlayStyle}
        className="absolute inset-0 bg-brown dark:bg-cream"
      />

      <Animated.View style={contentStyle} className="items-center px-8">
        <View className="bg-sage rounded-full p-6 mb-6">
          <Sparkles size={40} color="#EEF0F3" />
        </View>

        <Text className="font-heading text-3xl font-bold text-brown dark:text-cream text-center mb-4">
          A Message From the Past
        </Text>

        <Text className="font-sans text-base text-muted-foreground text-center">
          Written on {formatDate(createdAt)}
        </Text>
      </Animated.View>

      <Animated.View
        style={elapsedStyle}
        className="absolute bottom-24 items-center"
      >
        <Text className="font-sans text-sm text-muted-foreground mb-1">
          Time elapsed
        </Text>
        <Text className="font-heading text-2xl font-bold text-sage">
          {elapsed}
        </Text>
      </Animated.View>
    </View>
  );
}
