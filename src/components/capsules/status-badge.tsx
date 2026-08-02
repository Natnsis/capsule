import { View, Text } from "react-native";
import type { CapsuleStatus } from "@/types/capsule";
import { Lock, Unlock, Archive, PenLine } from "lucide-react-native";
import { colors } from "@/constants/colors";

interface StatusBadgeProps {
  status: CapsuleStatus;
}

const config: Record<CapsuleStatus, { label: string; icon: any; classes: string; textClasses: string; iconColor: string }> = {
  draft: {
    label: "Draft",
    icon: PenLine,
    classes: "bg-muted dark:bg-brown-light",
    textClasses: "text-muted-foreground",
    iconColor: colors.mutedForeground,
  },
  sealed: {
    label: "Sealed",
    icon: Lock,
    classes: "bg-sage/20",
    textClasses: "text-sage",
    iconColor: colors.sage,
  },
  ready: {
    label: "Ready to Open",
    icon: Unlock,
    classes: "bg-primary",
    textClasses: "text-cream",
    iconColor: colors.cream,
  },
  opened: {
    label: "Opened",
    icon: Archive,
    classes: "bg-muted dark:bg-brown-light",
    textClasses: "text-muted-foreground",
    iconColor: colors.mutedForeground,
  },
};

export function StatusBadge({ status }: StatusBadgeProps) {
  const { icon: Icon, classes, textClasses, iconColor } = config[status];

  return (
    <View className={`flex-row items-center rounded-full px-3 py-1 gap-1.5 ${classes}`}>
      <Icon size={12} color={iconColor} />
      <Text className={`font-sans text-xs font-semibold ${textClasses}`}>
        {config[status].label}
      </Text>
    </View>
  );
}
