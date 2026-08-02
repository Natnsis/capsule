import { View, TextInput } from "react-native";
import { Search } from "lucide-react-native";
import { colors } from "@/constants/colors";

interface SearchBarProps {
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
}

export function SearchBar({
  value,
  onChangeText,
  placeholder = "Search capsules...",
}: SearchBarProps) {
  return (
    <View className="flex-row items-center bg-muted dark:bg-brown-light rounded-2xl px-4 py-2.5">
      <Search size={16} color={colors.mutedForeground} />
      <TextInput
        className="flex-1 font-sans text-brown dark:text-cream text-sm ml-2.5"
        placeholder={placeholder}
        placeholderTextColor={colors.mutedForeground}
        value={value}
        onChangeText={onChangeText}
      />
    </View>
  );
}
