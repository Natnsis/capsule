import { useEffect, useState } from "react";
import { Text, Animated, Image } from "react-native";
import { CheckCircle, XCircle } from "lucide-react-native";
import { colors } from "@/constants/colors";

type ToastVariant = "success" | "error" | "info";

interface ToastProps {
  message: string;
  variant?: ToastVariant;
  visible: boolean;
  onHide: () => void;
  duration?: number;
}

const bgColors: Record<ToastVariant, string> = {
  success: "bg-sage",
  error: "bg-destructive",
  info: "bg-brown-card",
};

export function Toast({
  message,
  variant = "info",
  visible,
  onHide,
  duration = 2500,
}: ToastProps) {
  const [opacity] = useState(() => new Animated.Value(0));
  const [translateY] = useState(() => new Animated.Value(-20));

  useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.timing(opacity, { toValue: 1, duration: 200, useNativeDriver: true }),
        Animated.timing(translateY, { toValue: 0, duration: 200, useNativeDriver: true }),
      ]).start();

      const timer = setTimeout(() => {
        Animated.parallel([
          Animated.timing(opacity, { toValue: 0, duration: 200, useNativeDriver: true }),
          Animated.timing(translateY, { toValue: -20, duration: 200, useNativeDriver: true }),
        ]).start(() => onHide());
      }, duration);

      return () => clearTimeout(timer);
    }
  }, [visible]);

  if (!visible) return null;

  const Icon = variant === "success" ? CheckCircle : variant === "error" ? XCircle : null;

  return (
    <Animated.View
      className={`absolute top-16 left-4 right-4 z-50 flex-row items-center ${bgColors[variant]} rounded-2xl px-4 py-3 shadow-lg`}
      style={{ opacity, transform: [{ translateY }] }}
    >
      {Icon ? (
        <Icon size={20} color={colors.cream} />
      ) : (
        <Image source={require("@/../assets/images/logo.png")} className="w-5 h-5" resizeMode="contain" />
      )}
      <Text className="font-sans text-sm font-medium text-cream ml-3 flex-1">
        {message}
      </Text>
    </Animated.View>
  );
}
