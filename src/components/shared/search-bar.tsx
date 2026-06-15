import { View, TextInput } from "react-native";
import { Search } from "lucide-react-native";

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
    <View className="flex-row items-center bg-muted rounded-full px-4 py-3 mx-4">
      <Search size={18} color="#7A6E71" className="mr-3" />
      <TextInput
        className="flex-1 font-sans text-brown dark:text-cream text-base"
        placeholder={placeholder}
        placeholderTextColor="#7A6E71"
        value={value}
        onChangeText={onChangeText}
      />
    </View>
  );
}
