import { useEffect, useState } from "react";
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
  destructive: "bg-destructive",
  cancel: "bg-muted dark:bg-brown-light",
};

const textStyles: Record<string, string> = {
  default: "text-cream",
  destructive: "text-destructive-foreground",
  cancel: "text-brown dark:text-cream",
};

export function Dialog({ visible, title, message, actions, onClose }: DialogProps) {
  const [fadeAnim] = useState(() => new Animated.Value(0));
  const [scaleAnim] = useState(() => new Animated.Value(0.9));

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
          className="bg-card dark:bg-brown-card rounded-3xl w-full max-w-sm overflow-hidden"
          style={{ opacity: fadeAnim, transform: [{ scale: scaleAnim }] }}
        >
          <Pressable onPress={(e) => e.stopPropagation()} className="px-6 pt-6 pb-4">
            {title ? (
              <Text className="font-heading text-xl font-bold text-brown dark:text-cream mb-2">
                {title}
              </Text>
            ) : null}
            {message ? (
              <Text className="font-sans text-base text-muted-foreground leading-6">
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
