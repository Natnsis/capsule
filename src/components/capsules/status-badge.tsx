import { View, Text } from "react-native";
import type { CapsuleStatus } from "@/types/capsule";
import { Lock, Unlock, Archive } from "lucide-react-native";

interface StatusBadgeProps {
  status: CapsuleStatus;
}

const config: Record<CapsuleStatus, { label: string; icon: any; classes: string; textClasses: string }> = {
  sealed: {
    label: "Sealed",
    icon: Lock,
    classes: "bg-sage/20",
    textClasses: "text-sage",
  },
  ready: {
    label: "Ready to Open",
    icon: Unlock,
    classes: "bg-primary",
    textClasses: "text-cream",
  },
  opened: {
    label: "Opened",
    icon: Archive,
    classes: "bg-muted",
    textClasses: "text-muted-foreground",
  },
};

export function StatusBadge({ status }: StatusBadgeProps) {
  const Icon = config[status].icon;

  return (
    <View className={`flex-row items-center rounded-full px-3 py-1 gap-1.5 ${config[status].classes}`}>
      <Icon size={12} />
      <Text className={`font-sans text-xs font-semibold ${config[status].textClasses}`}>
        {config[status].label}
      </Text>
    </View>
  );
}
