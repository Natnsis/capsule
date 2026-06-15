import { TouchableOpacity, View } from "react-native";
import { Sun, Moon } from "lucide-react-native";
import { useThemeStore } from "@/stores/theme-store";

export function ThemeToggle() {
  const { isDark, setDark } = useThemeStore();

  return (
    <TouchableOpacity
      onPress={() => setDark(!isDark)}
      className="bg-muted rounded-full p-2"
    >
      {isDark ? (
        <Sun size={20} color="#F2EFEA" />
      ) : (
        <Moon size={20} color="#41393C" />
      )}
    </TouchableOpacity>
  );
}
