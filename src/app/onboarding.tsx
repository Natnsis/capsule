import { useState } from "react";
import { View, Text, Dimensions } from "react-native";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Pen, Clock, Heart } from "lucide-react-native";

import { Button } from "@/components/ui/button";
import { useOnboardingStore } from "@/stores/onboarding-store";

const { width } = Dimensions.get("window");

const slides = [
  {
    icon: Pen,
    title: "Write to Your\nFuture Self",
    subtitle:
      "Capture your thoughts, memories, and dreams. Seal them in a time capsule for a future version of you to discover.",
  },
  {
    icon: Clock,
    title: "Set a Date in\nthe Future",
    subtitle:
      "Choose when your capsule opens — a month, a year, or a decade from now. The waiting makes it magical.",
  },
  {
    icon: Heart,
    title: "Rediscover Your\nPast Self",
    subtitle:
      "When the time comes, open your capsule and reconnect with who you were. A message from your past, delivered to your future.",
  },
];

export default function OnboardingScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { setCompleted } = useOnboardingStore();
  const [currentSlide, setCurrentSlide] = useState(0);

  const slide = slides[currentSlide];
  const Icon = slide.icon;
  const isLast = currentSlide === slides.length - 1;

  const handleNext = () => {
    if (isLast) {
      setCompleted();
      router.replace("/(tabs)");
    } else {
      setCurrentSlide((prev) => prev + 1);
    }
  };

  const handleSkip = () => {
    setCompleted();
    router.replace("/(tabs)");
  };

  return (
    <View
      className="flex-1 bg-cream dark:bg-brown"
      style={{ paddingTop: insets.top }}
    >
      <View className="flex-row justify-end px-6 pt-4">
        {!isLast && (
          <Text
            onPress={handleSkip}
            className="font-sans text-base text-muted-foreground"
          >
            Skip
          </Text>
        )}
      </View>

      <View className="flex-1 items-center justify-center px-8">
        <View className="bg-sage/10 rounded-full p-10 mb-10">
          <Icon size={64} color="#82B090" />
        </View>

        <Text className="font-heading text-4xl font-bold text-brown dark:text-cream text-center mb-4">
          {slide.title}
        </Text>

        <Text className="font-sans text-base text-muted-foreground text-center leading-7 mb-12">
          {slide.subtitle}
        </Text>

        <View className="flex-row gap-2 mb-10">
          {slides.map((_, idx) => (
            <View
              key={idx}
              className={`h-2 rounded-full ${
                idx === currentSlide
                  ? "w-8 bg-sage"
                  : "w-2 bg-muted-foreground/30"
              }`}
            />
          ))}
        </View>

        <Button
          label={isLast ? "Begin Your Journey" : "Next"}
          size="lg"
          onPress={handleNext}
          className="w-full"
        />
      </View>
    </View>
  );
}
