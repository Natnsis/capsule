import { View, TouchableOpacity, Text } from "react-native";
import { Tabs, useRouter, usePathname } from "expo-router";
import { Home, Archive, Settings } from "lucide-react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

const tabs = [
  { name: "index", title: "Home", icon: Home },
  { name: "archive", title: "Archive", icon: Archive },
  { name: "settings", title: "Settings", icon: Settings },
];

export default function TabLayout() {
  const router = useRouter();
  const pathname = usePathname();
  const insets = useSafeAreaInsets();

  const currentTab = (() => {
    if (pathname === "/" || pathname === "/(tabs)") return "index";
    const parts = pathname.split("/");
    return parts[parts.length - 1] || "index";
  })();

  const navigateToTab = (name: string) => {
    const path = name === "index" ? "/(tabs)" : `/(tabs)/${name}`;
    router.replace(path as any);
  };

  return (
    <Tabs
      screenOptions={{ headerShown: false }}
      tabBar={({}) => (
        <View
          className="absolute bottom-0 left-0 right-0 items-center pb-2"
          style={{ paddingBottom: insets.bottom + 8 }}
        >
          <View className="flex-row items-center bg-brown dark:bg-[#2E282A] rounded-full px-6 py-2 gap-2 shadow-lg">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = currentTab === tab.name;

              return (
                <TouchableOpacity
                  key={tab.name}
                  onPress={() => navigateToTab(tab.name)}
                  className={`flex-row items-center rounded-full px-4 py-2 ${
                    isActive ? "bg-sage" : ""
                  }`}
                >
                  <Icon
                    size={18}
                    color={isActive ? "#F2EFEA" : "#7A6E71"}
                  />
                  {isActive && (
                    <Text className="text-cream font-sans text-sm font-semibold ml-2">
                      {tab.title}
                    </Text>
                  )}
                </TouchableOpacity>
              );
            })}
          </View>
        </View>
      )}
    >
      <Tabs.Screen name="index" />
      <Tabs.Screen name="archive" />
      <Tabs.Screen name="settings" />
    </Tabs>
  );
}
