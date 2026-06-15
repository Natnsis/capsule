import { View, Text } from "react-native";
import { Inbox, Clock, Archive } from "lucide-react-native";

const icons = {
  sealed: Clock,
  ready: Inbox,
  opened: Archive,
};

type EmptyStateType = keyof typeof icons;

interface EmptyStateProps {
  type: EmptyStateType;
  title?: string;
  subtitle?: string;
}

const defaults: Record<EmptyStateType, { title: string; subtitle: string }> = {
  sealed: {
    title: "No sealed capsules",
    subtitle: "Write a message to your future self to get started.",
  },
  ready: {
    title: "Nothing to open yet",
    subtitle: "Your sealed capsules will appear here when they're ready.",
  },
  opened: {
    title: "No memories yet",
    subtitle: "Opened capsules will be archived here.",
  },
};

export function EmptyState({ type, title, subtitle }: EmptyStateProps) {
  const Icon = icons[type];
  const copy = { ...defaults[type], title: title ?? defaults[type].title, subtitle: subtitle ?? defaults[type].subtitle };

  return (
    <View className="items-center justify-center py-16 px-8">
      <View className="bg-muted rounded-full p-6 mb-6">
        <Icon size={40} color="#7A6E71" />
      </View>
      <Text className="font-heading text-xl font-semibold text-brown dark:text-cream text-center mb-2">
        {copy.title}
      </Text>
      <Text className="font-sans text-base text-muted-foreground text-center leading-6">
        {copy.subtitle}
      </Text>
    </View>
  );
}
