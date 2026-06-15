import { useEffect, useRef } from "react";
import { Text, Animated } from "react-native";
import { CheckCircle, XCircle, Info } from "lucide-react-native";

type ToastVariant = "success" | "error" | "info";

interface ToastProps {
  message: string;
  variant?: ToastVariant;
  visible: boolean;
  onHide: () => void;
  duration?: number;
}

const icons = {
  success: CheckCircle,
  error: XCircle,
  info: Info,
};

const bgColors = {
  success: "bg-sage",
  error: "bg-red-500",
  info: "bg-brown dark:bg-[#5E4F53]",
};

const textColors = {
  success: "text-cream",
  error: "text-white",
  info: "text-cream",
};

export function Toast({
  message,
  variant = "info",
  visible,
  onHide,
  duration = 2500,
}: ToastProps) {
  const opacity = useRef(new Animated.Value(0)).current;
  const translateY = useRef(new Animated.Value(-20)).current;

  useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.timing(opacity, {
          toValue: 1,
          duration: 200,
          useNativeDriver: true,
        }),
        Animated.timing(translateY, {
          toValue: 0,
          duration: 200,
          useNativeDriver: true,
        }),
      ]).start();

      const timer = setTimeout(() => {
        Animated.parallel([
          Animated.timing(opacity, {
            toValue: 0,
            duration: 200,
            useNativeDriver: true,
          }),
          Animated.timing(translateY, {
            toValue: -20,
            duration: 200,
            useNativeDriver: true,
          }),
        ]).start(() => onHide());
      }, duration);

      return () => clearTimeout(timer);
    }
  }, [visible]);

  if (!visible) return null;

  const Icon = icons[variant];

  return (
    <Animated.View
      className={`absolute top-16 left-4 right-4 z-50 flex-row items-center ${bgColors[variant]} rounded-2xl px-4 py-3 shadow-lg`}
      style={{
        opacity,
        transform: [{ translateY }],
      }}
    >
      <Icon size={20} color="#F2EFEA" />
      <Text className={`font-sans text-sm font-medium ${textColors[variant]} ml-3 flex-1`}>
        {message}
      </Text>
    </Animated.View>
  );
}
