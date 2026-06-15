import { useState } from "react";
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  Switch,
  TextInput,
  Alert,
} from "react-native";
import type { LucideIcon } from "lucide-react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import {
  Moon,
  Sun,
  Bell,
  User,
  Trash2,
  ChevronRight,
  PenLine,
} from "lucide-react-native";

import { useThemeStore } from "@/stores/theme-store";
import { useProfileStore } from "@/stores/profile-store";
import { useCapsuleStats } from "@/hooks/use-capsules";
import { NotificationService } from "@/services/notification-service";
import { CapsuleRepository } from "@/db/repositories/capsule-repository";
import { Toast } from "@/components/shared/toast";

export default function SettingsScreen() {
  const insets = useSafeAreaInsets();
  const { isDark, setDark } = useThemeStore();
  const { name, setName } = useProfileStore();
  const { data: stats } = useCapsuleStats();

  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [editingName, setEditingName] = useState(false);
  const [nameInput, setNameInput] = useState(name);
  const [toast, setToast] = useState<{
    message: string;
    variant: "success" | "error" | "info";
  } | null>(null);

  const handleSaveName = () => {
    const trimmed = nameInput.trim();
    if (trimmed) {
      setName(trimmed);
      setEditingName(false);
      setToast({ message: "Name saved", variant: "success" });
    }
  };

  const handleDeleteAll = () => {
    Alert.alert(
      "Delete All Data",
      "This will permanently delete all your capsules. This action cannot be undone.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete All",
          style: "destructive",
          onPress: async () => {
            const capsules = await CapsuleRepository.getAll();
            for (const c of capsules) {
              if (c.notificationId) {
                await NotificationService.cancelReminder(c.notificationId);
              }
              await CapsuleRepository.delete(c.id);
            }
            setToast({ message: "All capsules deleted", variant: "success" });
          },
        },
      ]
    );
  };

  const statCards = [
    { label: "Total", value: stats?.total ?? 0, color: "text-brown dark:text-cream" },
    { label: "Sealed", value: stats?.sealed ?? 0, color: "text-brown dark:text-cream" },
    { label: "Ready", value: stats?.ready ?? 0, color: "text-sage" },
    { label: "Opened", value: stats?.opened ?? 0, color: "text-brown dark:text-cream" },
  ];

  return (
    <>
      <Toast
        message={toast?.message ?? ""}
        variant={toast?.variant ?? "info"}
        visible={!!toast}
        onHide={() => setToast(null)}
      />
      <ScrollView
        className="flex-1 bg-[#F2EFEA] dark:bg-[#41393C]"
        contentContainerStyle={{ paddingBottom: 120 }}
      >
        <View style={{ paddingTop: insets.top + 16 }} className="px-4 pb-4">
          <Text className="font-heading text-3xl font-bold text-[#41393C] dark:text-[#F2EFEA] mb-1">
            Settings
          </Text>
          <Text className="font-sans text-base text-[#7A6E71] mb-6">
            Manage your preferences and data
          </Text>

          {/* Name card */}
          <View className="bg-[#F2EFEA] dark:bg-[#4E4449] rounded-2xl p-5 mb-6 border border-[#D5D0CA]/50">
            <View className="flex-row items-center gap-4">
              <View className="w-14 h-14 rounded-full bg-sage items-center justify-center">
                <Text className="font-heading text-2xl font-bold text-[#F2EFEA]">
                  {(name || "G").charAt(0).toUpperCase()}
                </Text>
              </View>
              <View className="flex-1">
                {editingName ? (
                  <View className="flex-row items-center gap-2">
                    <TextInput
                      className="flex-1 bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-xl px-3 py-2 font-sans text-[#41393C] dark:text-[#F2EFEA] text-base"
                      value={nameInput}
                      onChangeText={setNameInput}
                      autoFocus
                      placeholder="Your name"
                      placeholderTextColor="#7A6E71"
                    />
                    <TouchableOpacity
                      onPress={handleSaveName}
                      className="bg-sage rounded-xl px-4 py-2"
                    >
                      <Text className="font-sans text-sm font-semibold text-[#F2EFEA]">Save</Text>
                    </TouchableOpacity>
                  </View>
                ) : (
                  <>
                    <Text className="font-heading text-lg font-semibold text-[#41393C] dark:text-[#F2EFEA]">
                      {name}
                    </Text>
                    <TouchableOpacity
                      onPress={() => { setNameInput(name); setEditingName(true); }}
                      className="flex-row items-center gap-1 mt-0.5"
                    >
                      <PenLine size={12} color="#82B090" />
                      <Text className="font-sans text-xs text-sage">Edit name</Text>
                    </TouchableOpacity>
                  </>
                )}
              </View>
            </View>
          </View>

          {/* Stats grid */}
          {stats && (
            <View className="flex-row flex-wrap gap-3 mb-6">
              {statCards.map((card) => (
                <View
                  key={card.label}
                  className="bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-2xl p-4 items-center"
                  style={{ width: "47%" }}
                >
                  <Text className={`font-heading text-3xl font-bold ${card.color} mb-1`}>
                    {card.value}
                  </Text>
                  <Text className="font-sans text-xs text-[#7A6E71]">{card.label}</Text>
                </View>
              ))}
            </View>
          )}

          {/* Settings sections */}
          <View className="mb-6">
            <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider mb-3 px-1">
              Appearance
            </Text>
            <View className="bg-[#F2EFEA] dark:bg-[#4E4449] rounded-2xl overflow-hidden border border-[#D5D0CA]/50">
              <View className="flex-row items-center px-4 py-4">
                <Moon size={20} color="#7A6E71" />
                <Text className="flex-1 font-sans text-base ml-3 text-[#41393C] dark:text-[#F2EFEA]">
                  Dark Mode
                </Text>
                <Switch
                  value={isDark}
                  onValueChange={setDark}
                  trackColor={{ false: "#D5D0CA", true: "#82B090" }}
                  thumbColor="#F2EFEA"
                />
              </View>
            </View>
          </View>

          <View className="mb-6">
            <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider mb-3 px-1">
              Notifications
            </Text>
            <View className="bg-[#F2EFEA] dark:bg-[#4E4449] rounded-2xl overflow-hidden border border-[#D5D0CA]/50">
              <View className="flex-row items-center px-4 py-4">
                <Bell size={20} color="#7A6E71" />
                <Text className="flex-1 font-sans text-base ml-3 text-[#41393C] dark:text-[#F2EFEA]">
                  Capsule Reminders
                </Text>
                <Switch
                  value={notificationsEnabled}
                  onValueChange={async (val) => {
                    setNotificationsEnabled(val);
                    if (!val) {
                      await NotificationService.cancelAll();
                    } else {
                      const permitted = await NotificationService.requestPermission();
                      if (!permitted) {
                        setNotificationsEnabled(false);
                        setToast({
                          message: "Enable notifications in your device settings",
                          variant: "error",
                        });
                      }
                    }
                  }}
                  trackColor={{ false: "#D5D0CA", true: "#82B090" }}
                  thumbColor="#F2EFEA"
                />
              </View>
            </View>
          </View>

          <View className="mb-6">
            <Text className="font-heading text-sm font-semibold text-[#7A6E71] uppercase tracking-wider mb-3 px-1">
              Danger Zone
            </Text>
            <View className="bg-[#F2EFEA] dark:bg-[#4E4449] rounded-2xl overflow-hidden border border-[#D5D0CA]/50">
              <TouchableOpacity
                onPress={handleDeleteAll}
                className="flex-row items-center px-4 py-4"
              >
                <Trash2 size={20} color="#EF4444" />
                <Text className="flex-1 font-sans text-base ml-3 text-red-500">
                  Delete All Data
                </Text>
                <ChevronRight size={18} color="#7A6E71" />
              </TouchableOpacity>
            </View>
          </View>

          <View className="items-center pb-8">
            <Text className="font-sans text-xs text-[#7A6E71]">
              TimeCapsule v1.0.0
            </Text>
            <Text className="font-sans text-xs text-[#7A6E71] mt-1">
              All data stored locally on this device
            </Text>
          </View>
        </View>
      </ScrollView>
    </>
  );
}
