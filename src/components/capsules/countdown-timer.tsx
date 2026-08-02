import { View, Text } from "react-native";
import { countdown } from "@/lib/date";
import { useEffect, useState } from "react";

interface CountdownTimerProps {
  openAt: number;
  size?: "sm" | "md" | "lg";
}

export function CountdownTimer({ openAt, size = "md" }: CountdownTimerProps) {
  const [, forceTick] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => forceTick((t) => t + 1), 60000);
    return () => clearInterval(interval);
  }, []);

  const display = countdown(openAt);

  const sizeClasses = {
    sm: "text-xs",
    md: "text-sm",
    lg: "text-lg font-semibold",
  };

  const isReady = display === "Ready to open";

  return (
    <View className="flex-row items-center">
      <View className={`w-2 h-2 rounded-full mr-2 ${isReady ? "bg-sage" : "bg-muted-foreground"}`} />
      <Text className={`font-sans ${sizeClasses[size]} ${isReady ? "text-sage font-semibold" : "text-muted-foreground"}`}>
        {display}
      </Text>
    </View>
  );
}
