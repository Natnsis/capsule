import { useEffect } from "react";
import { View } from "react-native";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSequence,
  Easing,
  runOnJS,
  type EasingFunction,
} from "react-native-reanimated";
import { Lock } from "lucide-react-native";
import * as Haptics from "expo-haptics";

interface SealAnimationProps {
  onComplete: () => void;
}

export function SealAnimation({ onComplete }: SealAnimationProps) {
  const scale = useSharedValue(0);
  const opacity = useSharedValue(0);
  const rotate = useSharedValue(0);

  useEffect(() => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

    opacity.value = withTiming(1, { duration: 300 });

    scale.value = withSequence(
      withTiming(1.2, { duration: 200, easing: Easing.out(Easing.back(1.5) as unknown as EasingFunction) }),
      withTiming(1, { duration: 300, easing: Easing.inOut(Easing.quad) })
    );

    rotate.value = withSequence(
      withTiming(-10, { duration: 150 }),
      withTiming(10, { duration: 150 }),
      withTiming(0, { duration: 200 })
    );

    const timer = setTimeout(() => {
      runOnJS(onComplete)();
    }, 1500);

    return () => clearTimeout(timer);
  }, []);

  const animatedIconStyle = useAnimatedStyle(() => ({
    transform: [
      { scale: scale.value },
      { rotate: `${rotate.value}deg` },
    ],
    opacity: opacity.value,
  }));

  const animatedTextStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
  }));

  return (
    <View className="flex-1 items-center justify-center bg-background">
      <Animated.View
        style={animatedIconStyle}
        className="bg-sage rounded-full p-8 mb-6"
      >
        <Lock size={48} color="#EEF0F3" />
      </Animated.View>
      <Animated.Text
        style={animatedTextStyle}
        className="font-heading text-2xl font-bold text-brown dark:text-cream mb-2"
      >
        Capsule Sealed
      </Animated.Text>
      <Animated.Text
        style={animatedTextStyle}
        className="font-sans text-base text-muted-foreground text-center px-8"
      >
        Your message is safely locked away until its opening date.
      </Animated.Text>
    </View>
  );
}
