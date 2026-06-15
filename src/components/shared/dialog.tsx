import { useEffect, useRef } from "react";
import { View, Text, Modal, TouchableOpacity, Animated, Pressable } from "react-native";

interface DialogAction {
  label: string;
  onPress: () => void;
  variant?: "default" | "destructive" | "cancel";
}

interface DialogProps {
  visible: boolean;
  title: string;
  message: string;
  actions: DialogAction[];
  onClose: () => void;
}

const buttonStyles: Record<string, string> = {
  default: "bg-sage",
  destructive: "bg-red-500",
  cancel: "bg-[#E4E0DA] dark:bg-[#5E4F53]",
};

const textStyles: Record<string, string> = {
  default: "text-[#F2EFEA]",
  destructive: "text-white",
  cancel: "text-[#41393C] dark:text-[#F2EFEA]",
};

export function Dialog({ visible, title, message, actions, onClose }: DialogProps) {
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const scaleAnim = useRef(new Animated.Value(0.9)).current;

  useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.timing(fadeAnim, { toValue: 1, duration: 200, useNativeDriver: true }),
        Animated.spring(scaleAnim, { toValue: 1, damping: 15, stiffness: 200, useNativeDriver: true }),
      ]).start();
    } else {
      fadeAnim.setValue(0);
      scaleAnim.setValue(0.9);
    }
  }, [visible]);

  return (
    <Modal transparent visible={visible} animationType="none" onRequestClose={onClose}>
      <Pressable className="flex-1 bg-black/50 justify-center items-center px-6" onPress={onClose}>
        <Animated.View
          className="bg-[#F2EFEA] dark:bg-[#4E4449] rounded-3xl w-full max-w-sm overflow-hidden"
          style={{ opacity: fadeAnim, transform: [{ scale: scaleAnim }] }}
        >
          <Pressable onPress={(e) => e.stopPropagation()} className="px-6 pt-6 pb-4">
            {title ? (
              <Text className="font-heading text-xl font-bold text-[#41393C] dark:text-[#F2EFEA] mb-2">
                {title}
              </Text>
            ) : null}
            {message ? (
              <Text className="font-sans text-base text-[#7A6E71] leading-6">
                {message}
              </Text>
            ) : null}
          </Pressable>
          <View className="flex-row gap-2 px-6 pb-6">
            {actions.map((action, i) => (
              <TouchableOpacity
                key={i}
                onPress={() => { action.onPress(); }}
                className={`flex-1 rounded-2xl py-3.5 items-center ${buttonStyles[action.variant || "default"]}`}
              >
                <Text className={`font-sans text-sm font-semibold ${textStyles[action.variant || "default"]}`}>
                  {action.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </Animated.View>
      </Pressable>
    </Modal>
  );
}
